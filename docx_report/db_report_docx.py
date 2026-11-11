#!/usr/bin/env python3
"""Builds a pre-filled Word report (.docx) from the HTML reports of db_report.

Two sub-commands:

  template  Turns an existing Word report into a reusable template: the body is
            cut from a given heading and replaced by the {{CONTENU}} marker, the
            month and the date become the {{MOIS}} and {{DATE}} markers.

  build     Reads the HTML reports of one or more servers (output/YYYYMMDD
            directories copied from the servers) and fills the template.

Only the Python standard library is used: a .docx is a ZIP archive of XML files.
The generated document is written in French; the tables keep the English labels
of the HTML reports.
"""

import argparse
import datetime
import os
import re
import sys
import zipfile
from html.parser import HTMLParser

# ------------------------------------------------------------------------------
# Paramètres : styles Word du modèle et valeurs par défaut
# ------------------------------------------------------------------------------

# Identifiants (w:styleId) des styles utilisés dans le modèle Word.
# Un style absent du modèle est signalé puis ignoré (le texte prend le style Normal).
STYLES = {
    "h1": "Titre1",
    "h2": "Titre2",
    "h3": "Titre3",
    "text": "AxTexteParagraphe",
    "bullet": "AxListe",
    "code": "AxCodeSource",
    "code_small": "AxCodeSourceMini",
    "todo": "AxInstructions",
    "table": "TableauGrille4-Accentuation2",
    "cell": "AxTabTexteParagraphe8Condens",
}

MARKER_CONTENT = "{{CONTENU}}"
MARKER_MONTH = "{{MOIS}}"
MARKER_DATE = "{{DATE}}"

# Largeur utile de la page en DXA (A4, marges gauche et droite de 1080) ; recalculée
# à partir du modèle quand celui-ci définit d'autres marges.
DEFAULT_TEXT_WIDTH = 9746

# Couleur de fond des cellules de statut
STATUS_FILL = {"CRITICAL": "F4B6B0", "WARNING": "FFE699", "OK": "C6E0B4"}
STATUS_ORDER = {"CRITICAL": 0, "WARNING": 1}

# Au-delà de cette longueur, une ligne de code passe dans le style de code réduit
CODE_WIDE_LINE = 88

MONTHS_FR = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet",
             "Août", "Septembre", "Octobre", "Novembre", "Décembre"]

# Titres des sections des rapports HTML relues par ce script
SEC_SERVER_HEALTH = "Server Health Summary"
SEC_DF = "Disk Space Usage (df -h)"
SEC_DB_HEALTH = "Database Health Summary"
SEC_TABLESPACES = "Tablespaces Details"
SEC_BACKUP_TYPES = "Last Successful Backup per Type"
SEC_RMAN_JOBS = "Last RMAN Backups"
SEC_ALERT_LOG = "Last Alert Log Errors"
SEC_EXPDP = "Datapump Export Log Verification"


def warn(message):
    print("[WARN] " + message, file=sys.stderr)


def fail(message):
    print("[ERROR] " + message, file=sys.stderr)
    sys.exit(1)


# ------------------------------------------------------------------------------
# Lecture des rapports HTML
# ------------------------------------------------------------------------------

class ReportParser(HTMLParser):
    """Découpe un rapport HTML en sections (une par <h2>), avec leurs tableaux et blocs <pre>."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.h1 = []
        self.sections = []
        self._section = None
        self._mode = None
        self._buffer = []
        self._table = None
        self._row = None

    def handle_starttag(self, tag, attrs):
        if tag in ("h1", "h2"):
            self._mode, self._buffer = tag, []
        elif tag == "table":
            self._table = []
        elif tag == "tr" and self._table is not None:
            self._row = []
        elif tag in ("td", "th") and self._row is not None:
            self._mode, self._buffer = "cell", []
        elif tag == "pre":
            self._mode, self._buffer = "pre", []
        elif tag == "br" and self._mode == "cell":
            self._buffer.append(" ")

    def handle_endtag(self, tag):
        if tag == "h1" and self._mode == "h1":
            self.h1.append("".join(self._buffer).strip())
            self._mode = None
        elif tag == "h2" and self._mode == "h2":
            self._section = {"title": "".join(self._buffer).strip(), "tables": [], "pres": []}
            self.sections.append(self._section)
            self._mode = None
        elif tag in ("td", "th") and self._mode == "cell":
            self._row.append(" ".join("".join(self._buffer).split()))
            self._mode = None
        elif tag == "tr" and self._row is not None:
            if self._row:
                self._table.append(self._row)
            self._row = None
        elif tag == "table" and self._table is not None:
            if self._section is not None and self._table:
                self._section["tables"].append(self._table)
            self._table = None
        elif tag == "pre" and self._mode == "pre":
            if self._section is not None:
                self._section["pres"].append("".join(self._buffer))
            self._mode = None

    def handle_data(self, data):
        if self._mode:
            self._buffer.append(data)


class Report:
    """Un fichier HTML relu : titres <h1> et sections."""

    def __init__(self, path):
        self.path = path
        parser = ReportParser()
        with open(path, encoding="utf-8", errors="replace") as handle:
            parser.feed(handle.read())
        self.h1 = parser.h1
        self.sections = parser.sections

    def section(self, title):
        for section in self.sections:
            if section["title"] == title:
                return section
        return None

    def table(self, title):
        """Premier tableau de la section : (en-tête, lignes), ou (None, []) s'il est absent."""
        section = self.section(title)
        if section is None or not section["tables"]:
            return None, []
        rows = section["tables"][0]
        return rows[0], rows[1:]

    def pre(self, title):
        section = self.section(title)
        if section is None or not section["pres"]:
            return None
        return section["pres"][0]


class Database:
    def __init__(self, sid, report):
        self.sid = sid
        self.report = report
        self.health = report.table(SEC_DB_HEALTH)[1]

    def check(self, prefix):
        """Ligne de la synthèse dont le nom du contrôle commence par prefix."""
        for row in self.health:
            if row and row[0].startswith(prefix):
                return row
        return None


class Server:
    def __init__(self, host):
        self.host = host
        self.timestamp = ""
        self.report = None
        self.health = []
        self.databases = []
        self.expdp = None


# Rapport_<host>_<YYYYMMDDHHMM>.html ou Rapport_<host>_<SID>_<YYYYMMDDHHMM>.html
RE_REPORT_FILE = re.compile(r"^Rapport_.*_(\d{12})\.html$")
RE_EXPDP_FILE = re.compile(r"^Summary_check_expdp_log_(.*)_(\d{12})\.html$")
RE_SERVER_H1 = re.compile(r"^Server Configuration Report for (\S+)$")
RE_DB_H1 = re.compile(r"^Database Report (\S+) on server (\S+)$")


def load_servers(directories):
    """Relit les rapports des répertoires donnés. Pour chaque serveur, seule l'exécution
    la plus récente (horodatage du nom de fichier) est conservée."""
    found = {}   # host -> timestamp -> {"server": Report, "dbs": {sid: Report}, "expdp": Report}

    for directory in directories:
        if not os.path.isdir(directory):
            fail("Not a directory: %s" % directory)
        for root, _dirs, files in os.walk(directory):
            for name in sorted(files):
                path = os.path.join(root, name)
                match = RE_EXPDP_FILE.match(name)
                if match:
                    host, timestamp = match.group(1), match.group(2)
                    found.setdefault(host, {}).setdefault(timestamp, {"dbs": {}})["expdp"] = Report(path)
                    continue
                match = RE_REPORT_FILE.match(name)
                if not match:
                    continue
                timestamp = match.group(1)
                report = Report(path)
                title = report.h1[0] if report.h1 else ""
                server_match = RE_SERVER_H1.match(title)
                db_match = RE_DB_H1.match(title)
                if server_match:
                    run = found.setdefault(server_match.group(1), {}).setdefault(timestamp, {"dbs": {}})
                    run["server"] = report
                elif db_match:
                    run = found.setdefault(db_match.group(2), {}).setdefault(timestamp, {"dbs": {}})
                    run["dbs"][db_match.group(1)] = report
                else:
                    warn("Unrecognized report, ignored: %s" % path)

    servers = []
    for host in sorted(found):
        timestamps = sorted(found[host])
        timestamp = timestamps[-1]
        if len(timestamps) > 1:
            warn("%s: %d runs found, using the most recent one (%s)." % (host, len(timestamps), timestamp))
        run = found[host][timestamp]
        server = Server(host)
        server.timestamp = timestamp
        server.report = run.get("server")
        if server.report is not None:
            server.health = server.report.table(SEC_SERVER_HEALTH)[1]
        else:
            warn("%s: no server report found (Rapport_%s_%s.html)." % (host, host, timestamp))
        for sid in sorted(run["dbs"]):
            server.databases.append(Database(sid, run["dbs"][sid]))
        if "expdp" in run:
            server.expdp = run["expdp"].pre(SEC_EXPDP)
        servers.append(server)
    return servers


# ------------------------------------------------------------------------------
# Fabrication du XML Word
# ------------------------------------------------------------------------------

def xml_escape(text):
    # Caractères de contrôle interdits en XML 1.0
    text = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", "", text)
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


class DocxWriter:
    """Accumule le XML des paragraphes et tableaux à insérer dans le modèle."""

    def __init__(self, available_styles, text_width):
        self.parts = []
        self.text_width = text_width
        self.styles = {}
        for key, style_id in STYLES.items():
            if style_id in available_styles:
                self.styles[key] = style_id
            else:
                warn("Style '%s' not found in the template: Word's default style is used instead." % style_id)
                self.styles[key] = None

    # --- paragraphes ---

    def _ppr(self, key, extra=""):
        style_id = self.styles.get(key)
        style = '<w:pStyle w:val="%s"/>' % style_id if style_id else ""
        if not style and not extra:
            return ""
        return "<w:pPr>%s%s</w:pPr>" % (style, extra)

    def _paragraph(self, key, text, bold=False, extra=""):
        run = ""
        if text:
            rpr = "<w:rPr><w:b/></w:rPr>" if bold else ""
            run = '<w:r>%s<w:t xml:space="preserve">%s</w:t></w:r>' % (rpr, xml_escape(text))
        return "<w:p>%s%s</w:p>" % (self._ppr(key, extra), run)

    def h1(self, text):
        self.parts.append(self._paragraph("h1", text))

    def h2(self, text):
        self.parts.append(self._paragraph("h2", text))

    def h3(self, text):
        self.parts.append(self._paragraph("h3", text))

    def text(self, text):
        self.parts.append(self._paragraph("text", text))

    def bullet(self, text):
        self.parts.append(self._paragraph("bullet", text))

    def todo(self, text):
        """Paragraphe repère : texte à rédiger par l'auteur du rapport."""
        self.parts.append(self._paragraph("todo", text))

    def code(self, text):
        """Bloc de code : un paragraphe par ligne, comme dans le modèle."""
        lines = text.rstrip().split("\n")
        key = "code"
        if max((len(line) for line in lines), default=0) > CODE_WIDE_LINE and self.styles.get("code_small"):
            key = "code_small"
        for line in lines:
            self.parts.append(self._paragraph(key, line.rstrip() or " "))

    # --- tableaux ---

    @staticmethod
    def _word_width(word, bold=False):
        """Largeur approximative d'un mot dans une cellule (8 pt), en DXA. Les majuscules et le
        gras sont plus larges : sous-estimer couperait un statut ou un nom de base en deux."""
        word = word[:18]
        width = sum(135 if char.isupper() else 100 for char in word)
        return int(width * (1.15 if bold else 1.0))

    def _column_widths(self, header, rows, bold_columns=()):
        """Largeurs proportionnelles à la longueur du contenu. Chaque colonne garde au moins la
        place de son mot le plus long (un statut ou un nom de base ne doit pas être coupé)."""
        padding = 260        # marges intérieures de la cellule
        weights, minimums = [], []
        for index, title in enumerate(header):
            cells = [row[index] for row in rows if index < len(row)]
            lengths = sorted(len(cell) for cell in cells)
            # 90e centile : une valeur exceptionnellement longue ne dicte pas la largeur
            typical = lengths[max(int(len(lengths) * 0.9) - 1, 0)] if lengths else 0
            widest = max([self._word_width(word, bold=True) for word in title.split()] +
                         [self._word_width(word, bold=index in bold_columns)
                          for cell in cells for word in cell.split()] + [0])
            weights.append(min(max(typical, 4), 55))
            minimums.append(widest + padding)

        total = float(sum(weights))
        if sum(minimums) >= self.text_width:
            # Trop de colonnes pour garantir les minimums : simple répartition proportionnelle
            widths = [int(self.text_width * weight / total) for weight in weights]
        else:
            # Chaque colonne reçoit son minimum, le reste est réparti selon la longueur du contenu
            spare = self.text_width - sum(minimums)
            widths = [minimum + int(spare * weight / total) for minimum, weight in zip(minimums, weights)]
        widths[-1] += self.text_width - sum(widths)
        return widths

    @staticmethod
    def _is_numeric(value):
        return bool(re.match(r"^-?\d*[.,]?\d+%?$", value))

    def _cell(self, lines, width, align=None, fill=None, bold=False, header=False):
        shading = '<w:shd w:val="clear" w:color="auto" w:fill="%s"/>' % fill if fill else ""
        extra = '<w:jc w:val="%s"/>' % align if align else ""
        paragraphs = "".join(self._paragraph("cell", line, bold=bold, extra=extra) for line in lines)
        return '<w:tc><w:tcPr><w:tcW w:w="%d" w:type="dxa"/>%s</w:tcPr>%s</w:tc>' % (width, shading, paragraphs)

    def table(self, header, rows, status_column=None, equal_widths=False):
        """Tableau au style du modèle. Une cellule peut contenir plusieurs lignes (liste de chaînes).
        status_column : indice de la colonne de statut, colorée selon OK / WARNING / CRITICAL."""
        def as_lines(cell):
            return cell if isinstance(cell, list) else [cell]

        flat_rows = [[" ".join(as_lines(cell)) if not isinstance(cell, list) else max(cell, key=len, default="")
                      for cell in row] for row in rows]
        if equal_widths:
            widths = [self.text_width // len(header)] * len(header)
            widths[-1] += self.text_width - sum(widths)
        else:
            widths = self._column_widths(header, flat_rows,
                                         bold_columns=() if status_column is None else (status_column,))
        numeric = [bool(flat_rows) and all(self._is_numeric(row[index]) for row in flat_rows
                                           if index < len(row) and row[index] not in ("", "-"))
                   and any(index < len(row) and row[index] not in ("", "-") for row in flat_rows)
                   for index in range(len(header))]

        style_id = self.styles.get("table")
        style = '<w:tblStyle w:val="%s"/>' % style_id if style_id else ""
        xml = ["<w:tbl><w:tblPr>%s" % style,
               '<w:tblW w:w="%d" w:type="dxa"/><w:jc w:val="center"/><w:tblLayout w:type="fixed"/>' % self.text_width,
               '<w:tblLook w:val="0420" w:firstRow="1" w:lastRow="0" w:firstColumn="0" w:lastColumn="0" '
               'w:noHBand="0" w:noVBand="1"/></w:tblPr><w:tblGrid>']
        xml.extend('<w:gridCol w:w="%d"/>' % width for width in widths)
        xml.append("</w:tblGrid>")

        # Ligne d'en-tête, répétée en haut de chaque page
        xml.append('<w:tr><w:trPr><w:cantSplit/><w:tblHeader/></w:trPr>')
        for index, title in enumerate(header):
            xml.append(self._cell([title], widths[index], align="center", header=True))
        xml.append("</w:tr>")

        for row in rows:
            xml.append("<w:tr><w:trPr><w:cantSplit/></w:trPr>")
            for index in range(len(header)):
                cell = row[index] if index < len(row) else ""
                lines = as_lines(cell)
                if index == status_column:
                    xml.append(self._cell(lines, widths[index], align="center",
                                          fill=STATUS_FILL.get(lines[0]), bold=True))
                else:
                    xml.append(self._cell(lines, widths[index], align="right" if numeric[index] else None))
            xml.append("</w:tr>")
        xml.append("</w:tbl>")
        self.parts.append("".join(xml))
        # Paragraphe vide : espace après le tableau, et séparation de deux tableaux consécutifs
        self.parts.append(self._paragraph("text", ""))

    def xml(self):
        return "".join(self.parts)


# ------------------------------------------------------------------------------
# Contenu du rapport
# ------------------------------------------------------------------------------

def plural(count, singular, plural_form=None):
    return "%d %s" % (count, singular if count < 2 else (plural_form or singular + "s"))


def number(value):
    """Convertit une valeur numérique d'un rapport (ex. '.00', '88.5') en float, None si impossible."""
    try:
        return float(value.replace(",", ".").replace("%", ""))
    except (ValueError, AttributeError):
        return None


def display_number(value):
    """SQL*Plus affiche '.46' (ou ',46' selon le NLS de la base) pour 0.46 : on rétablit le zéro."""
    if re.match(r"^[.,]\d", value):
        return "0" + value
    if re.match(r"^-[.,]\d", value):
        return "-0" + value[1:]
    return value


def truncate(text, limit):
    return text if len(text) <= limit else text[:limit - 1].rstrip() + "…"


def collect_findings(servers):
    """Lignes WARNING / CRITICAL de toutes les synthèses : (statut, cible, contrôle, valeur, seuil)."""
    findings = []
    for server in servers:
        for row in server.health:
            if len(row) >= 4 and row[3] in STATUS_ORDER:
                findings.append((row[3], server.host, row[0], row[1], row[2]))
        for database in server.databases:
            for row in database.health:
                if len(row) >= 4 and row[3] in STATUS_ORDER:
                    findings.append((row[3], "%s (%s)" % (database.sid, server.host), row[0], row[1], row[2]))
    findings.sort(key=lambda finding: STATUS_ORDER[finding[0]])
    return findings


def all_ok(rows_list, prefixes):
    """Vrai si les contrôles commençant par un des préfixes existent et sont tous OK ou INFO."""
    seen = False
    for rows in rows_list:
        for row in rows:
            if len(row) >= 4 and any(row[0].startswith(prefix) for prefix in prefixes):
                seen = True
                if row[3] in STATUS_ORDER:
                    return False
    return seen


def write_scope(doc, servers):
    doc.h2("Périmètre")
    doc.text("Voici la liste des bases en cours d'exécution sur chaque serveur :")
    rows = []
    for server in servers:
        rows.append(["", server.host, [database.sid for database in server.databases] or ["-"]])
    doc.table(["Environnement", "Serveur", "Bases"], rows, equal_widths=True)


def write_summary(doc, servers, args):
    doc.h2("Synthèse")
    findings = collect_findings(servers)
    critical = sum(1 for finding in findings if finding[0] == "CRITICAL")
    warning = len(findings) - critical

    if not findings:
        doc.text("Durant cette vérification, aucun point critique ni avertissement n'a été relevé.")
    else:
        doc.text("Durant cette vérification, les contrôles automatiques ont relevé %s et %s :" % (
            plural(critical, "point critique", "points critiques"), plural(warning, "avertissement")))
        doc.table(["Status", "Target", "Check", "Value"],
                  [[finding[0], finding[1], finding[2], truncate(finding[3], 110)] for finding in findings],
                  status_column=0)

    server_health = [server.health for server in servers]
    db_health = [database.health for server in servers for database in server.databases]
    statements = []
    if all_ok(server_health, ["Filesystem usage"]):
        statements.append("Aucun système de fichiers n'est proche de la saturation.")
    if all_ok(db_health, ["Last successful database backup", "Failed RMAN jobs", "Datafiles without backup"]):
        statements.append("Les sauvegardes RMAN sont à jour et sans erreur sur toutes les bases.")
    if all_ok(db_health, ["Tablespace usage"]):
        statements.append("Aucun tablespace n'est proche de la saturation.")
    if all_ok(db_health, ["Alert log ORA- errors"]):
        statements.append("Les fichiers alertlog ne remontent aucune erreur ORA- sur les 7 derniers jours.")
    exports = [server.expdp for server in servers if server.expdp]
    if exports and all(text.startswith("No ORA- errors") for text in exports):
        statements.append("Les exports Datapump ne présentent aucune erreur.")

    if statements:
        doc.text("Concernant les autres points de vérification :")
        for statement in statements:
            doc.bullet(statement)

    doc.todo("À compléter : analyse des points relevés et actions réalisées.")


def write_servers(doc, servers):
    doc.h2("Les serveurs")
    for server in servers:
        doc.h3("Serveur %s" % server.host)
        if server.report is None:
            doc.text("Le rapport serveur n'a pas été trouvé.")
            continue
        if server.health:
            doc.table(["Check", "Value", "Threshold", "Status"], server.health, status_column=3)
        else:
            doc.text("La synthèse de santé du serveur est absente du rapport.")
        df_output = server.report.pre(SEC_DF)
        if df_output:
            doc.text("Occupation des systèmes de fichiers :")
            # Le bloc <pre> commence par la commande, suivie d'une ligne vide
            lines = [line for line in df_output.strip().split("\n")]
            if lines and lines[0].strip() == "df -h":
                lines = ["$ df -h"] + [line for line in lines[1:] if line.strip()]
            doc.code("\n".join(lines))
    doc.todo("À compléter : commentaires sur l'état des serveurs.")


def write_databases(doc, servers, args):
    doc.h2("Les bases de données")
    databases = [(server, database) for server in servers for database in server.databases]
    if not databases:
        doc.text("Aucun rapport de base de données n'a été trouvé.")
        return

    doc.text("Résultat des contrôles automatiques pour chaque base :")
    rows = []
    for server, database in databases:
        counts = {"OK": 0, "WARNING": 0, "CRITICAL": 0}
        for row in database.health:
            if len(row) >= 4 and row[3] in counts:
                counts[row[3]] += 1
        worst = "CRITICAL" if counts["CRITICAL"] else ("WARNING" if counts["WARNING"] else "OK")
        if not database.health:
            worst = "-"
        rows.append([server.host, database.sid, str(counts["OK"]), str(counts["WARNING"]),
                     str(counts["CRITICAL"]), worst])
    doc.table(["Server", "Database", "OK", "Warning", "Critical", "Status"], rows, status_column=5)

    for server, database in databases:
        if not database.health:
            continue
        if args.health == "full":
            rows = database.health
        else:
            rows = [row for row in database.health if len(row) >= 4 and row[3] in STATUS_ORDER]
            if not rows:
                continue
        doc.h3("Base %s (%s)" % (database.sid, server.host))
        doc.table(["Check", "Value", "Threshold", "Status"],
                  [[row[0], truncate(row[1], 160), row[2], row[3]] for row in rows], status_column=3)

    if args.health != "full":
        clean = [database.sid for _server, database in databases
                 if database.health and not any(len(row) >= 4 and row[3] in STATUS_ORDER for row in database.health)]
        if clean:
            doc.text("Tous les contrôles sont satisfaisants sur : %s." % ", ".join(clean))


def write_backups(doc, servers):
    doc.h2("Les sauvegardes RMAN")
    rows = []
    failed = []
    for server in servers:
        for database in server.databases:
            _header, types = database.report.table(SEC_BACKUP_TYPES)
            if not types:
                rows.append([server.host, database.sid, "none in RMAN history", "-", "-", "-"])
            for line in types:
                line = (line + ["", "", "", ""])[:4]
                rows.append([server.host, database.sid, line[0], line[1], display_number(line[2]), line[3]])
            header, jobs = database.report.table(SEC_RMAN_JOBS)
            if header and "Status" in header:
                status_index = header.index("Status")
                for job in jobs:
                    if status_index < len(job) and job[status_index] != "COMPLETED":
                        failed.append([server.host, database.sid] + job[1:])
                        failed_header = ["Server", "Database"] + header[1:]

    if not rows:
        doc.text("Aucun rapport de base de données n'a été trouvé.")
        return
    doc.text("Dernière sauvegarde réussie par base et par type :")
    doc.table(["Server", "Database", "Type", "Last Successful", "Age (days)", "Successful Jobs in History"], rows)

    if failed:
        doc.text("Sauvegardes qui ne se sont pas terminées avec le statut COMPLETED, parmi les dernières exécutions :")
        doc.table(failed_header, failed[:30])
    else:
        doc.text("Toutes les dernières sauvegardes listées dans les rapports se sont terminées "
                 "avec le statut COMPLETED.")
    doc.todo("À compléter : commentaires sur les sauvegardes.")


def write_tablespaces(doc, servers, args):
    doc.h2("Occupation des tablespaces")
    selected = []
    total = 0
    for server in servers:
        for database in server.databases:
            header, lines = database.report.table(SEC_TABLESPACES)
            if not header:
                continue
            index = {name: position for position, name in enumerate(header)}
            # Rapports d'une version antérieure : une seule colonne "% Used", calculée sur la taille max
            if "% Used (max)" not in index and "% Used" in index:
                index["% Used (max)"] = index["% Used"]
            needed = ["DB/PDB Name", "Tablespace", "Allocated MB", "Used MB", "MaxSize MB", "% Used (max)"]
            if any(name not in index for name in needed):
                warn("%s: unexpected columns in '%s', section ignored." % (database.sid, SEC_TABLESPACES))
                continue
            shown = needed[:5] + ["% Used (alloc)", "% Used (max)"]
            for line in lines:
                if len(line) < len(header):
                    continue
                total += 1
                percent = number(line[index["% Used (max)"]])
                if percent is not None and percent >= args.tbs_min_pct:
                    selected.append((percent, [server.host, database.sid] +
                                     [display_number(line[index[name]]) if name in index else "-"
                                      for name in shown]))

    threshold = ("%g" % args.tbs_min_pct).replace(".", ",")
    if total == 0:
        doc.text("Aucune information sur les tablespaces n'a été trouvée dans les rapports.")
        return
    if not selected:
        doc.text("Aucun tablespace ne dépasse %s %% de sa taille maximale (%s)." % (
            threshold, plural(total, "tablespace contrôlé", "tablespaces contrôlés")))
    else:
        selected.sort(key=lambda item: -item[0])
        doc.text("%s sur %d à %s %% ou plus de la taille maximale (autoextend compris) :" % (
            plural(len(selected), "tablespace"), total, threshold))
        doc.table(["Server", "Database", "DB/PDB Name", "Tablespace", "Allocated MB", "Used MB",
                   "MaxSize MB", "% Used (alloc)", "% Used (max)"], [row for _percent, row in selected])
        doc.text("% Used (alloc) : espace utilisé rapporté à l'espace actuellement alloué. "
                 "% Used (max) : espace utilisé rapporté à la taille maximale, autoextend compris ; "
                 "c'est cette valeur qui est comparée au seuil.")
    doc.todo("À compléter : commentaires sur les tablespaces.")


def write_exports(doc, servers):
    doc.h2("Les exports Datapump")
    results = [(server.host, server.expdp) for server in servers if server.expdp]
    if not results:
        doc.text("Le contrôle des logs d'export Datapump n'a pas été exécuté sur ces serveurs.")
        return
    for host, text in results:
        lines = text.strip().split("\n")
        if len(lines) == 1:
            doc.bullet("%s : %s" % (host, lines[0]))
        else:
            doc.text("Erreurs ORA- relevées dans les logs d'export du serveur %s :" % host)
            shown = lines[:30]
            if len(lines) > len(shown):
                shown.append("... (%d more lines)" % (len(lines) - len(shown)))
            doc.code("\n".join(shown))
    doc.todo("À compléter : commentaires sur les exports.")


def write_alert_log(doc, servers, args):
    doc.h2("Erreurs alertlog significatives")
    rows = []
    details = []
    for server in servers:
        for database in server.databases:
            check = database.check("Alert log ORA- errors")
            if check:
                rows.append([server.host, database.sid, check[1], check[3]])
            header, lines = database.report.table(SEC_ALERT_LOG)
            if header and lines:
                details.append((server, database, header, lines))

    if rows:
        doc.text("Nombre d'erreurs ORA- dans les fichiers alertlog sur les 7 derniers jours :")
        doc.table(["Server", "Database", "Alert log ORA- errors (last 7 days)", "Status"], rows, status_column=3)
    if not details:
        doc.text("Aucune erreur n'est listée dans les rapports.")
    for server, database, header, lines in details:
        doc.h3("Base %s (%s)" % (database.sid, server.host))
        shown = lines[:args.alert_rows]
        doc.text("Dernières erreurs (%d affichées sur %d dans le rapport) :" % (len(shown), len(lines)))
        doc.table(header[:2], [[line[0], truncate(line[1] if len(line) > 1 else "", 300)] for line in shown])
    doc.todo("À compléter : analyse des erreurs significatives.")


def build_content(servers, args, available_styles, text_width):
    doc = DocxWriter(available_styles, text_width)
    write_scope(doc, servers)
    write_summary(doc, servers, args)
    doc.h1("Compte rendu")
    write_servers(doc, servers)
    write_databases(doc, servers, args)
    write_backups(doc, servers)
    write_tablespaces(doc, servers, args)
    write_exports(doc, servers)
    write_alert_log(doc, servers, args)
    return doc.xml()


# ------------------------------------------------------------------------------
# Manipulation du docx (ZIP de XML)
# ------------------------------------------------------------------------------

# Paragraphe le plus interne (sans paragraphe imbriqué, ex. zone de texte)
RE_PARAGRAPH = re.compile(r"<w:p(?: [^>]*[^/>])?>(?:(?!<w:p[ >]).)*?</w:p>", re.S)
RE_TEXT = re.compile(r"(<w:t(?: [^>]*)?>)([^<]*)(</w:t>)")


def xml_unescape(text):
    return text.replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"').replace("&amp;", "&")


def paragraph_text(paragraph):
    return xml_unescape("".join(match.group(2) for match in RE_TEXT.finditer(paragraph)))


def set_paragraph_text(paragraph, text):
    """Place text dans le premier <w:t> du paragraphe et vide les suivants : Word découpe
    souvent un même texte en plusieurs morceaux (<w:r>)."""
    state = {"first": True}

    def replace(match):
        if state["first"]:
            state["first"] = False
            return '<w:t xml:space="preserve">' + xml_escape(text) + match.group(3)
        return match.group(1) + match.group(3)

    return RE_TEXT.sub(replace, paragraph)


def replace_in_paragraphs(xml, old, new):
    """Remplace old par new dans le texte des paragraphes, même si old est réparti sur
    plusieurs morceaux. Retourne (xml, nombre de paragraphes modifiés)."""
    count = [0]

    def replace(match):
        paragraph = match.group(0)
        text = paragraph_text(paragraph)
        if old not in text:
            return paragraph
        count[0] += 1
        return set_paragraph_text(paragraph, text.replace(old, new))

    return RE_PARAGRAPH.sub(replace, xml), count[0]


def read_docx(path):
    """Retourne la liste ordonnée [(ZipInfo, contenu)] des fichiers du docx."""
    if not os.path.isfile(path):
        fail("File not found: %s" % path)
    with zipfile.ZipFile(path) as archive:
        return [(info, archive.read(info.filename)) for info in archive.infolist() if not info.is_dir()]


def write_docx(path, entries):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as archive:
        for info, data in entries:
            archive.writestr(info.filename, data)


def get_entry(entries, name):
    for info, data in entries:
        if info.filename == name:
            return data.decode("utf-8")
    fail("Not a Word document: %s is missing." % name)


def set_entry(entries, name, text):
    for index, (info, _data) in enumerate(entries):
        if info.filename == name:
            entries[index] = (info, text.encode("utf-8"))
            return
    fail("%s is missing." % name)


def text_part_names(entries):
    """Corps du document, en-têtes et pieds de page : les fichiers où chercher les marqueurs."""
    return [info.filename for info, _data in entries
            if re.match(r"^word/(document|header\d*|footer\d*)\.xml$", info.filename)]


def enable_field_update(entries):
    """Demande à Word de recalculer les champs (table des matières) à l'ouverture."""
    settings = get_entry(entries, "word/settings.xml")
    if "<w:updateFields" in settings:
        return
    # L'ordre des éléments de settings.xml est imposé par le schéma : updateFields se place
    # juste avant le premier de ces éléments, ou à défaut en fin de fichier.
    following = re.search(r"<(?:w:hdrShapeDefaults|w:footnotePr|w:endnotePr|w:compat|w:docVars|w:rsids|m:mathPr|"
                          r"w:attachedSchema|w:themeFontLang|w:clrSchemeMapping|w:doNotIncludeSubdocsInStats|"
                          r"w:doNotAutoCompressPictures|w:forceUpgrade|w:captions|w:readModeInkLockDown|"
                          r"w:smartTagType|w:schemaLibrary|w:shapeDefaults|w:doNotEmbedSmartTags|"
                          r"w:decimalSymbol|w:listSeparator|w14:|w15:|w16)[ />]|</w:settings>", settings)
    settings = settings[:following.start()] + '<w:updateFields w:val="true"/>' + settings[following.start():]
    set_entry(entries, "word/settings.xml", settings)


def page_text_width(document_xml):
    """Largeur utile de la dernière section du document, en DXA."""
    sections = re.findall(r"<w:sectPr.*?</w:sectPr>", document_xml, re.S)
    if sections:
        size = re.search(r'<w:pgSz [^>]*w:w="(\d+)"', sections[-1])
        left = re.search(r'<w:pgMar [^>]*w:left="(\d+)"', sections[-1])
        right = re.search(r'<w:pgMar [^>]*w:right="(\d+)"', sections[-1])
        if size and left and right:
            return int(size.group(1)) - int(left.group(1)) - int(right.group(1))
    return DEFAULT_TEXT_WIDTH


# ------------------------------------------------------------------------------
# Commande build
# ------------------------------------------------------------------------------

def command_build(args):
    servers = load_servers(args.directories)
    if not servers:
        fail("No db_report HTML report found in: %s" % ", ".join(args.directories))

    entries = read_docx(args.template)
    document = get_entry(entries, "word/document.xml")
    available_styles = set(re.findall(r'w:styleId="([^"]+)"', get_entry(entries, "word/styles.xml")))

    # Mois par défaut : celui de l'exécution la plus récente
    latest = max(server.timestamp for server in servers)
    month = args.month or "%s %s" % (MONTHS_FR[int(latest[4:6]) - 1], latest[:4])
    date = args.date or datetime.date.today().strftime("%d/%m/%Y")

    content = build_content(servers, args, available_styles, page_text_width(document))

    # Le paragraphe qui porte le marqueur est remplacé par le contenu généré
    position = None
    for match in RE_PARAGRAPH.finditer(document):
        if MARKER_CONTENT in paragraph_text(match.group(0)):
            position = match
            break
    if position is None:
        fail("Marker %s not found in the template %s." % (MARKER_CONTENT, args.template))
    document = document[:position.start()] + content + document[position.end():]
    set_entry(entries, "word/document.xml", document)

    for name in text_part_names(entries):
        xml = get_entry(entries, name)
        xml, _count = replace_in_paragraphs(xml, MARKER_MONTH, month)
        xml, _count = replace_in_paragraphs(xml, MARKER_DATE, date)
        set_entry(entries, name, xml)

    enable_field_update(entries)
    write_docx(args.output, entries)

    databases = sum(len(server.databases) for server in servers)
    print("[INFO] %s written: %s, %s." % (args.output, plural(len(servers), "server"),
                                          plural(databases, "database")))
    for server in servers:
        print("[INFO]   %s (run %s): %s" % (server.host, server.timestamp,
                                            ", ".join(database.sid for database in server.databases) or "no database"))


# ------------------------------------------------------------------------------
# Commande template
# ------------------------------------------------------------------------------

def split_body(body):
    """Découpe le contenu de <w:body> en éléments de premier niveau (paragraphes, tableaux, sectPr...)."""
    elements = []
    depth = 0
    start = 0
    for match in re.finditer(r"<(/?)([\w:]+)(?:\s[^>]*?)?(/?)>", body):
        closing, _name, self_closing = match.group(1), match.group(2), match.group(3)
        if self_closing:
            if depth == 0:
                elements.append(body[start:match.end()])
                start = match.end()
        elif closing:
            depth -= 1
            if depth == 0:
                elements.append(body[start:match.end()])
                start = match.end()
        else:
            depth += 1
    return elements


def reset_toc(elements, styles):
    """Remplace les entrées en cache de la table des matières par une ligne d'attente :
    Word la recalcule à l'ouverture du document."""
    begin = end = None
    for index, element in enumerate(elements):
        if begin is None and re.search(r"<w:instrText[^>]*>\s*TOC ", element):
            begin = index
        elif begin is not None and 'w:fldCharType="end"' in element and "PAGEREF" not in element:
            end = index
            break
    if begin is None or end is None:
        return elements
    instruction = re.search(r"<w:instrText[^>]*>(\s*TOC [^<]*)</w:instrText>", elements[begin]).group(1)
    style = '<w:pPr><w:pStyle w:val="TM1"/></w:pPr>' if "TM1" in styles else ""
    placeholder = ('<w:p>%s<w:r><w:fldChar w:fldCharType="begin" w:dirty="true"/></w:r>'
                   '<w:r><w:instrText xml:space="preserve">%s</w:instrText></w:r>'
                   '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
                   '<w:r><w:t>Table des matières : clic droit, puis « Mettre à jour les champs ».</w:t></w:r>'
                   '<w:r><w:fldChar w:fldCharType="end"/></w:r></w:p>') % (style, instruction)
    return elements[:begin] + [placeholder] + elements[end + 1:]


def drop_unused_media(entries):
    """Retire les images qui ne sont plus référencées après la coupe du corps du document."""
    rels_name = "word/_rels/document.xml.rels"
    rels = get_entry(entries, rels_name)
    document = get_entry(entries, "word/document.xml")
    used = set(re.findall(r'r:(?:embed|id|link|pict)="([^"]+)"', document))
    removed_targets = set()

    def keep(match):
        relation = match.group(0)
        rel_id = re.search(r'Id="([^"]+)"', relation).group(1)
        is_image = "/relationships/image" in relation
        is_link = "/relationships/hyperlink" in relation
        if (is_image or is_link) and rel_id not in used:
            if is_image:
                removed_targets.add("word/" + re.search(r'Target="([^"]+)"', relation).group(1))
            return ""
        return relation

    rels = re.sub(r"<Relationship [^>]*/>", keep, rels)
    set_entry(entries, rels_name, rels)
    # Une image peut être partagée avec un en-tête : elle n'est retirée que si plus rien ne la cite
    other_rels = "".join(data.decode("utf-8", "replace") for info, data in entries
                         if info.filename.endswith(".rels"))
    for target in removed_targets:
        if os.path.basename(target) not in other_rels:
            entries[:] = [(info, data) for info, data in entries if info.filename != target]


def command_template(args):
    entries = read_docx(args.source)
    document = get_entry(entries, "word/document.xml")
    styles = set(re.findall(r'w:styleId="([^"]+)"', get_entry(entries, "word/styles.xml")))

    match = re.search(r"(<w:body>)(.*)(</w:body>)", document, re.S)
    if not match:
        fail("No <w:body> in %s." % args.source)
    elements = split_body(match.group(2))

    # Coupe : du titre donné jusqu'à la fin, en conservant la section finale (marges, en-tête, pied)
    cut = None
    for index, element in enumerate(elements):
        if element.startswith("<w:p") and re.search(r'<w:pStyle w:val="(Titre|Heading)\d"', element) \
                and paragraph_text(element).strip() == args.content_from:
            cut = index
            break
    if cut is None:
        fail("Heading '%s' not found in %s." % (args.content_from, args.source))
    tail = [element for element in elements[cut:] if element.startswith("<w:sectPr")]
    style_id = STYLES["text"]
    style = '<w:pPr><w:pStyle w:val="%s"/></w:pPr>' % style_id if style_id in styles else ""
    marker = "<w:p>%s<w:r><w:t>%s</w:t></w:r></w:p>" % (style, MARKER_CONTENT)
    elements = reset_toc(elements[:cut], styles) + [marker] + tail

    document = document[:match.start(2)] + "".join(elements) + document[match.end(2):]
    set_entry(entries, "word/document.xml", document)

    for name in text_part_names(entries):
        xml = get_entry(entries, name)
        for old, new, label in ((args.month, MARKER_MONTH, "month"), (args.date, MARKER_DATE, "date")):
            if old:
                xml, count = replace_in_paragraphs(xml, old, new)
                if count:
                    print("[INFO] %s: %s '%s' replaced by %s (%d paragraph(s))." % (name, label, old, new, count))
        set_entry(entries, name, xml)

    drop_unused_media(entries)
    enable_field_update(entries)
    write_docx(args.output, entries)
    print("[INFO] Template written: %s (content marker placed at heading '%s')." % (args.output, args.content_from))


# ------------------------------------------------------------------------------
# Ligne de commande
# ------------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Builds a pre-filled Word report from the HTML reports of db_report.")
    commands = parser.add_subparsers(dest="command", required=True)

    build = commands.add_parser("build", help="fill a template with the HTML reports")
    build.add_argument("-t", "--template", required=True, help="Word template containing the %s marker" % MARKER_CONTENT)
    build.add_argument("-o", "--output", required=True, help="Word document to write")
    build.add_argument("--month", help="month shown on the cover, e.g. 'Novembre 2026' (default: month of the reports)")
    build.add_argument("--date", help="document date, e.g. 11/11/2026 (default: today)")
    build.add_argument("--tbs-min-pct", type=float, default=70.0,
                       help="list only the tablespaces at or above this percentage of their maximum size (default: 70)")
    build.add_argument("--health", choices=("issues", "full"), default="issues",
                       help="per database, show only the WARNING/CRITICAL checks (issues, default) or all checks (full)")
    build.add_argument("--alert-rows", type=int, default=10,
                       help="number of alert log errors listed per database (default: 10)")
    build.add_argument("directories", nargs="+", metavar="DIR",
                       help="directory holding the HTML reports of a server (searched recursively)")
    build.set_defaults(function=command_build)

    template = commands.add_parser("template", help="turn an existing Word report into a template")
    template.add_argument("source", help="existing Word report")
    template.add_argument("output", help="template to write")
    template.add_argument("--content-from", required=True, metavar="HEADING",
                          help="heading from which the body is replaced by the generated content, e.g. 'Périmètre'")
    template.add_argument("--month", help="month text of the source report to turn into %s, e.g. 'Juin 2026'" % MARKER_MONTH)
    template.add_argument("--date", help="date text of the source report to turn into %s, e.g. 16/06/2026" % MARKER_DATE)
    template.set_defaults(function=command_template)

    args = parser.parse_args()
    args.function(args)


if __name__ == "__main__":
    main()
