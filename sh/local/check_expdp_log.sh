#!/bin/bash
# script pour vérifier les logs des fichiers datapump et voir si des erreurs sont présentes

# Importe les fonctions utilitaires
source "$(dirname "$0")/../utils.sh"

# --- Fonctions ---

# Affiche le début et la fin d'un fichier log.
# Le titre de la base n'est affiché que lorsqu'elle change : la base est le premier
# sous-répertoire de EXPDP_DIR (ex. /u04/expdp/<BASE>/export_...log), quelle que soit
# la profondeur de EXPDP_DIR.
previous_db=""
show_log_excerpt() {
  local file="$1"
  local relative_path db_name

  relative_path="${file#"${EXPDP_DIR%/}"/}"
  case "${relative_path}" in
    */*) db_name="${relative_path%%/*}" ;;
    *)   db_name="$(basename "${EXPDP_DIR}")" ;;   # log directement dans EXPDP_DIR
  esac

  if [ "${db_name}" != "${previous_db}" ]; then
    echo "<br>"
    print_h2 "$(echo "${db_name}" | html_escape)"
    previous_db="${db_name}"
  fi

  print_h3 "$(echo "${file}" | html_escape)"
  echo "<pre>"
  head -10 "$file" | html_escape        # les 10 premières lignes
  echo "</pre><pre>"
  tail -10 "$file" | html_escape        # les 10 dernières lignes
  echo "</pre>"
}

# --- Script principal ---

# EXPDP_DIR="/u04/backup" : la variable d'environnement est chargée depuis le fichier .env

CURRENT_DATE=$(date +%Y_%m)   # date au format 2025_04

print_h2 "Datapump Export Log Verification"

#  vérifier si une erreur ORA- est présente dans les fichiers logs
print_h3 "Checking for errors in the logs of the month ${CURRENT_DATE}:"

if [ -z "${EXPDP_DIR:-}" ]; then
    echo "<pre>The EXPDP_DIR variable is not defined. Unable to verify Datapump logs.</pre>"
elif [ ! -d "${EXPDP_DIR}" ]; then
    echo "<pre>The directory EXPDP_DIR ('${EXPDP_DIR}') does not exist or is not accessible.</pre>"
else
    # La recherche porte sur les logs du mois, comme les extraits affichés plus bas
    RESULT=$(find "${EXPDP_DIR}" -iname "export_*${CURRENT_DATE}*.log" -exec grep -H "ORA-" "{}" \; | sort)
    if [ -z "$RESULT" ]; then
        echo "<pre>No ORA- errors detected in the export log files of the month ${CURRENT_DATE}.</pre>"
    else
        echo "<pre>"
        echo "$RESULT" | html_escape
        echo "</pre>"
    fi

    # afficher le début et la fin des logs du mois pour voir si les exports se sont bien déroulés
    print_h1 "First 10 and last 10 lines of the log files for the month ${CURRENT_DATE}"

    # Tri par chemin : les logs d'une même base se suivent
    log_count=0
    while IFS= read -r log_file; do
        [ -n "${log_file}" ] || continue
        show_log_excerpt "${log_file}"
        log_count=$((log_count + 1))
    done < <(find "${EXPDP_DIR}" -iname "export_*${CURRENT_DATE}*.log" | sort)

    if [ "${log_count}" -eq 0 ]; then
        echo "<pre>No export log file found for the month ${CURRENT_DATE}.</pre>"
    fi
fi
