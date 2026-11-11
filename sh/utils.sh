#!/bin/bash

# Fichier de fonctions utilitaires pour les scripts de rapport

# Fonction: log_info
# Description: Affiche un message d'information dans les logs avec un timestamp.
# Paramètres:
#   $1 - Le message à afficher.
log_info() {
  echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - ${1}"
}

# Fonction: log_warn
# Description: Affiche un message d'avertissement dans les logs avec un timestamp.
log_warn() {
  echo "[WARN] $(date +'%Y-%m-%d %H:%M:%S') - ${1}"
}

# Fonction: run_sql_script
# Description: Execute un script SQL (precede de l'en-tete SQL*Plus) avec "/ as sysdba",
#   ajoute sa sortie au fichier HTML et signale les erreurs ORA-/SP2-/PLS- d'execution.
#   Les lignes situees dans une cellule de tableau (<td> ou <th>) sont ignorees :
#   ce sont des donnees ou des titres de colonne (ex. messages de l'alert log), pas des erreurs du script.
#   Si DB_REPORT_ERROR_LOG est definie, les erreurs y sont consignees pour le recapitulatif final.
# Parametres:
#   $1 - Fichier d'en-tete SQL*Plus (ex. sql/sql_header.txt)
#   $2 - Script SQL a executer
#   $3 - Fichier HTML de sortie
run_sql_script() {
  local sql_header_file="$1"
  local script_file="$2"
  local html_file="$3"
  local output errors

  output="$(cat "${sql_header_file}" "${script_file}" | sqlplus -s / as sysdba 2>&1)" || true
  printf '%s\n' "${output}" >> "${html_file}"

  errors="$(printf '%s\n' "${output}" | awk '
    /^<t[dh]/    { incell = 1 }
    /^<\/t[dh]>/ { incell = 0 }
    !incell && /^(ORA|SP2|PLS)-[0-9]+/ { print }')"

  if [ -n "${errors}" ]; then
    log_warn "SQL error in ${script_file} (${ORACLE_SID:-?}): $(printf '%s\n' "${errors}" | head -1)"
    if [ -n "${DB_REPORT_ERROR_LOG:-}" ]; then
      printf '%s\n' "${errors}" | sed "s|^|${ORACLE_SID:-?} ${script_file}: |" >> "${DB_REPORT_ERROR_LOG}"
    fi
  fi
}

# Fonction: list_db_sids
# Description: Liste les SID des instances de base en cours d'execution (une par ligne, triee).
#   Seuls les processus ora_pmon_<SID> sont retenus, ce qui exclut ASM (asm_pmon_+ASM),
#   APX (apx_pmon_+APX) et MGMTDB (mdb_pmon_-MGMTDB). Le SID est pris en entier,
#   meme s'il contient un underscore.
list_db_sids() {
  ps -eo args | sed -n 's/^ora_pmon_//p' | sort -u
}

# Fonction: set_oracle_env
# Description: Positionne l'environnement Oracle (ORACLE_SID, ORACLE_HOME, PATH) pour un SID.
# Parametres:
#   $1 - Le SID de l'instance.
set_oracle_env() {
  export ORAENV_ASK=NO
  export ORACLE_SID="$1"
  # shellcheck source=/dev/null
  . oraenv -s > /dev/null
}

# Fonction: sql_value
# Description: Execute une requete sur l'instance courante ("/ as sysdba") et retourne
#   sa valeur unique, sans espaces autour. Retourne une chaine vide si rien n'est renvoye.
# Parametres:
#   $1 - La requete, terminee par un point-virgule.
sql_value() {
  printf 'set pages 0 feedback off heading off verify off lines 500 trimspool on\n%s\nexit\n' "$1" \
    | sqlplus -s / as sysdba 2>/dev/null \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep . | tail -1
}

# Affiche un titre H3
print_h3() {
  echo "<h3>$1</h3>"
}

# Affiche un titre H2
print_h2() {
  echo "<h2>$1</h2>"
}

# Affiche un titre H1
print_h1() {
  echo "<h1>$1</h1>"
}

html_escape() {
  sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

# Exécute une commande et affiche sa sortie dans une balise <pre>
# Si la commande échoue, elle affiche un message d'erreur mis en évidence.
run_and_print() {
  local cmd="$1"
  local cmd_html
  local output

  cmd_html=$(echo "${cmd}" | html_escape)

  echo "<br><pre>"
  echo "<b style=\"color:red;\">${cmd_html}</b>"
  echo ""

  if output=$(eval "${cmd}" 2>&1); then
    echo "$output" | html_escape
  else
    echo "<div class=\"error-block\">"
    echo "ERREUR: La commande a échoué avec le message suivant :"
    echo "$output" | html_escape
    echo "</div>"
  fi
  echo "</pre>"
}
