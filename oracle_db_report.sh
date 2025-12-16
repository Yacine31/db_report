#!/bin/bash
# Script for generating HTML reports for Oracle databases.
# Collects system information, ASM, PDBs and configurations via Bash/SQL scripts.

# Stops the script on error (errors, undefined variables, failed pipes)
set -euo pipefail

source sh/utils.sh

# --- Initial Configuration ---
# Defines global variables and loads user configuration.
# Defines the language for commands (avoids locale issues)
export LANG=en_US
# Generates a timestamp for file naming
timestamp="$(date +%Y%m%d%H%M)"
# Retrieves the server's hostname
hostname="$(hostname)"

# Loads configuration from .env if the file exists
if [ -f .env ]; then
  # shellcheck source=.env
  source .env
fi

# Defines the output directory (can be overridden by the OUTPUT_DIR variable in .env)
output_dir_base="${OUTPUT_DIR:-"output"}"
output_dir="${output_dir_base}/$(date +%Y%m%d)"

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
        # le script sh/09_os_info.sh dure 20 secondes : message d'info pour l'utilisateur
        if [ "${script_file}" = "sh/09_os_info.sh" ]; then
          log_info "Executing script: ${script_file} ... 20-second pause for vmstat"
        fi
        # Exécute le script Bash et ajoute sa sortie au rapport
        bash "${script_file}" >> "${html_report_file}"
        ;;
      sql)
        # Concatène l'en-tête SQL avec le script et l'exécute via sqlplus
        cat "${sql_header_file}" "${script_file}" | sqlplus -s / as sysdba >> "${html_report_file}"
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

# Defines the HTML report file name
html_report_file="${output_dir}/Rapport_"${hostname}"_"${timestamp}".html"

# Copies the HTML header and adds the anchor for the "back to top" link
cat html/00_html_header.html > "${html_report_file}"
echo '<div id="top"></div>' >> "${html_report_file}"

# Generates formatted date for display in the report
current_date="$(date +"%d/%m/%Y %Hh%M")"
{
  echo "<h1>Server Configuration Report for "${hostname}"</h1>"
  echo "<h2>Date: "${current_date}"</h2>"
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
# Detects running Oracle databases
# Excludes ASM and APX instances to focus on user databases
#-----------------------------------------------------------------------------
database_sids="$(ps -eaf | grep pmon | egrep -v 'grep|ASM|APX1' | cut -d '_' -f3 || true)"

if [ -z "${database_sids}" ]; then
  echo "[WARN] No Oracle databases detected. Script terminated."
  exit 0
fi

log_info "Starting report generation for databases: "${database_sids}""

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

   # Copie l'en-tête HTML et ajoute l'ancre pour le lien "retour en haut"
   cat html/00_html_header.html > "${html_report_file}"
   echo '<div id="top"></div>' >> "${html_report_file}"
  
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

  # If an ASM instance is detected, execute ASM scripts
  if [ "$(ps -ef | grep pmon | grep ASM | wc -l)" -gt 0 ]; then
      # Execute ASM scripts on this instance
      execute_scripts "ASM Instance Configuration" "asm/*.sql" "sql" "sql/sql_header.txt"
  fi

  execute_scripts "Database Configuration "${ORACLE_SID}"" "sql/*.sql" "sql" "sql/sql_header.txt"

  # Ajoute le pied de page HTML au rapport
  cat html/99_html_footer.html >> "${html_report_file}"
  # Définit le nom du fichier HTML du rapport
  html_report_file="${output_dir}/Rapport_"${hostname}"_"${ORACLE_SID}"_"${timestamp}".html"
  
done
#--------------- 

# Once all reports are generated, execute the summary script to aggregate data
# And the RMAN backup evolution chart
export OUTPUT_DIR="${output_dir}"
export DATETIME="${timestamp}"
export HNAME="${hostname}"

log_info "Executing summary scripts."
bash summary.sh

log_info "Generating RMAN chart."
bash generate_rman_chart.sh

log_info "Script finished."