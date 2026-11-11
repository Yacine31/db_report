#!/bin/bash
# Script for generating HTML reports for Oracle databases.
# Collects system information, ASM, PDBs and configurations via Bash/SQL scripts.

# Stops the script on error (errors, undefined variables, failed pipes)
set -euo pipefail

# Se place dans le repertoire du script : tous les chemins (sh/, sql/, html/) sont relatifs
cd "$(dirname "$0")"

source sh/utils.sh

# ------------------------------------------------------------------------------
# Function: usage
# ------------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Usage: oracle_db_report.sh [options]

Generates HTML reports for the server and its running Oracle databases.

Options:
  -s SID      Report only this database (can be repeated: -s DB1 -s DB2).
              Default: all running databases.
  --vmstat    Add a live vmstat sample to the server report (about 40 s).
  -h, --help  Show this help and exit.

Output: <OUTPUT_DIR>/YYYYMMDD/ (OUTPUT_DIR defaults to ./output, can be
set in .env).
EOF
}

# --- Command line ---
requested_sids=""
# Lue par sh/09_os_info.sh : 1 = ajoute l'echantillon vmstat au rapport serveur
export DB_REPORT_VMSTAT=0

while [ $# -gt 0 ]; do
  case "$1" in
    -s)
      if [ $# -lt 2 ]; then
        echo "[ERROR] Option -s requires a SID." >&2
        usage >&2
        exit 2
      fi
      requested_sids="${requested_sids} $2"
      shift 2
      ;;
    --vmstat)
      DB_REPORT_VMSTAT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# Detects running Oracle databases (ASM, APX and MGMTDB instances are excluded)
running_sids="$(list_db_sids)"

# Avec -s : chaque SID demande doit correspondre a une instance demarree,
# sinon on s'arrete avant de produire un rapport vide.
for requested_sid in ${requested_sids}; do
  if ! printf '%s\n' "${running_sids}" | grep -qx -- "${requested_sid}"; then
    echo "[ERROR] Database '${requested_sid}' is not running on this server." >&2
    echo "[ERROR] Running databases: $(echo ${running_sids:-none})" >&2
    exit 1
  fi
done

if [ -n "${requested_sids}" ]; then
  database_sids="$(echo ${requested_sids})"
else
  database_sids="$(echo ${running_sids})"
fi

# --- Initial Configuration ---
# Defines global variables and loads user configuration.
# Defines the language for commands (avoids locale issues)
export LANG=en_US
# Generates a timestamp for file naming
timestamp="$(date +%Y%m%d%H%M)"
# Retrieves the server's hostname
# Nom court : evite un point dans les noms de fichiers (ex. srv.lan)
hostname="$(hostname -s)"

# Loads configuration from .env if the file exists
if [ -f .env ]; then
  # shellcheck source=.env
  source .env
fi

# Defines the output directory (can be overridden by the OUTPUT_DIR variable in .env)
output_dir_base="${OUTPUT_DIR:-"output"}"
output_dir="${output_dir_base}/$(date +%Y%m%d)"

# Fichier temporaire ou run_sql_script (sh/utils.sh) consigne les erreurs SQL rencontrees.
# Il est relu en fin d'execution pour le recapitulatif, puis supprime.
DB_REPORT_ERROR_LOG="$(mktemp)"
export DB_REPORT_ERROR_LOG
trap 'rm -f "${DB_REPORT_ERROR_LOG}"' EXIT

# ------------------------------------------------------------------------------
# Function: execute_scripts
# ------------------------------------------------------------------------------
# Description: Executes a series of scripts (Bash or SQL) and adds their output to the HTML report.
#               First checks if scripts match the pattern.
# Parameters:
#   $1 (section_title) - Section title in the HTML report.
#   $2 (script_pattern) - Path to scripts (e.g., "sh/*.sh").
#   $3 (script_type) - Script type: "sh" for Bash, "sql" for SQL.
#   $4 (sql_header_file) - SQL header file (optional, only used for "sql").
#   Example: execute_scripts "System Configuration" "sh/*.sh" "sh"
execute_scripts() {
  local section_title="$1"
  local script_pattern="$2"
  local script_type="$3"
  local sql_header_file="${4:-}"

  # Vérifie s'il y a des fichiers correspondants au pattern pour éviter les erreurs
  # Utilise ls au lieu de find pour compatibilité, avec shellcheck désactivé pour SC2012
  # shellcheck disable=SC2012
  # if [ -z "$(ls -1 "${script_pattern}" 2>/dev/null)" ]; then
  #   log_info "No script found for pattern '${script_pattern}', section ignored."
  #   return
  # fi

  echo "<h1>"${section_title}"</h1>" >> "${html_report_file}"
  # Boucle sur chaque script correspondant au pattern
  for script_file in ${script_pattern}; do
    log_info "Executing script: ${script_file}"
    case "${script_type}" in
      sh)
        # Exécute le script Bash et ajoute sa sortie au rapport
        bash "${script_file}" >> "${html_report_file}"
        ;;
      sql)
        # Exécute le script SQL (précédé de l'en-tête) et consigne les erreurs ORA-/SP2-
        run_sql_script "${sql_header_file}" "${script_file}" "${html_report_file}"
        ;;
    esac
  done
  echo "<br><br>" >> "${html_report_file}"
  echo "<p><a href=\"#top\">Back to top</a></p>" >> "${html_report_file}"
} # execute_scripts

#------------------------------ Main Script ------------------------------
# Orchestrates report generation for each detected database.
#------------------------------------------------------------------------------

# Crée le répertoire de sortie si nécessaire
mkdir -p "${output_dir}"

#-------------------------------- SERVERS --------------------------------
#------------------------------------------------------------------------------
log_info "Starting report generation for server: "${hostname}""
if [ "${DB_REPORT_VMSTAT}" = "1" ]; then
  log_info "Option --vmstat: the server report includes a vmstat sample (about 40 seconds)."
fi

# Defines the HTML report file name
html_report_file="${output_dir}/Rapport_"${hostname}"_"${timestamp}".html"

# Copies the HTML header (it opens <body> and holds the anchor for the "back to top" link)
cat html/00_html_header.html > "${html_report_file}"

# Generates formatted date for display in the report
current_date="$(date +"%d/%m/%Y %Hh%M")"
{
  echo "<h1>Server Configuration Report for "${hostname}"</h1>"
  echo "<h3>Date: "${current_date}"</h3>"
  echo "<h2>Hostname: "${hostname}"</h2>"
  echo "<br><br>"
 } >> "${html_report_file}"

# Exécute les scripts de collecte d'informations via la fonction execute_scripts
execute_scripts "System Configuration" "sh/*.sh" "sh"

# Ajoute le pied de page HTML au rapport
cat html/99_html_footer.html >> "${html_report_file}"
log_info "Report generated: "${html_report_file}""
#---------------

#--------------------------------- DATABASES ---------------------------------
# database_sids = bases demandees avec -s, sinon toutes les bases demarrees
#-----------------------------------------------------------------------------
if [ -z "${database_sids}" ]; then
  echo "[WARN] No Oracle databases detected. Script terminated."
  exit 0
fi

log_info "Starting report generation for databases: ${database_sids}"

for database_sid in ${database_sids}; do
  # Disables oraenv prompts and sets the current database
  export ORAENV_ASK=NO
  export ORACLE_SID="${database_sid}"

  log_info "Processing database: "${ORACLE_SID}""
  # Configures the Oracle environment for the current database
  # shellcheck source=/dev/null
  . oraenv -s > /dev/null

  # Définit le nom du fichier HTML du rapport
  html_report_file="${output_dir}/Rapport_"${hostname}"_"${ORACLE_SID}"_"${timestamp}".html"

   # --- HTML Report Generation for this Database ---
   # Initializes the HTML file with header and general info.

   # Copie l'en-tête HTML (il ouvre <body> et contient l'ancre du lien "retour en haut")
   cat html/00_html_header.html > "${html_report_file}"

  # Generates formatted date for display in the report
  current_date="$(date +"%d/%m/%Y %Hh%M")"
  {
    echo "<h1>Database Report "${ORACLE_SID}" on server "${hostname}"</h1>"
    echo "<h3>Date : "${current_date}"</h3>"
    echo "<h3>Hostname : "${hostname}"</h3>"
    echo "<h2>Database : "${ORACLE_SID}"</h2>"
    echo "<br><br>"
   } >> "${html_report_file}"

  # Si la base est un CDB (Container Database), exécute les scripts pour les PDBs
  if [ "$(/bin/sh sql/cdb/is_CDB.sh | tail -1)" = "YES" ]; then
    execute_scripts "PDB Information" "sql/cdb/*.sql" "sql" "sql/sql_header.txt"
  fi

  # Si la base participe à une configuration Data Guard, exécute les scripts DG
  if [ "$(/bin/sh sql/dataguard/is_dataguard.sh | tail -1)" = "YES" ]; then
    execute_scripts "Data Guard Configuration" "sql/dataguard/*.sql" "sql" "sql/sql_header.txt"
  fi

  # If an ASM instance is detected, execute ASM scripts
  if [ "$(ps -ef | grep pmon | grep ASM | wc -l)" -gt 0 ]; then
      # Execute ASM scripts on this instance
      execute_scripts "ASM Instance Configuration" "asm/*.sql" "sql" "sql/sql_header.txt"
  fi

  execute_scripts "Database Configuration "${ORACLE_SID}"" "sql/*.sql" "sql" "sql/sql_header.txt"

  # Ajoute le pied de page HTML au rapport
  cat html/99_html_footer.html >> "${html_report_file}"

done
#---------------

# Once all reports are generated, execute the summary script to aggregate data
# And the RMAN backup evolution chart
export OUTPUT_DIR="${output_dir}"
export DATETIME="${timestamp}"
export HNAME="${hostname}"
# Bases a traiter par summary.sh et generate_rman_chart.sh (memes bases que ci-dessus)
export DB_REPORT_SIDS="${database_sids}"

log_info "Executing summary scripts."
bash summary.sh

log_info "Generating RMAN chart."
bash generate_rman_chart.sh

# --- Recapitulatif des erreurs SQL rencontrees pendant l'execution ---
if [ -s "${DB_REPORT_ERROR_LOG}" ]; then
  log_warn "$(wc -l < "${DB_REPORT_ERROR_LOG}") SQL error(s) detected during the run:"
  while IFS= read -r error_line; do
    log_warn "  ${error_line}"
  done < "${DB_REPORT_ERROR_LOG}"
else
  log_info "No SQL error detected."
fi

log_info "Script finished."
