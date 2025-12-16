#!/bin/bash
# script pour vérifier les logs des fichiers datapump et voir si des erreurs sont présentes

# Importe les fonctions utilitaires
source "$(dirname "$0")/../utils.sh"

# --- Script principal ---

# EXPDP_DIR="/u04/backup" : la variable d'environnement est chargée depuis le fichier .env

CURRENT_DATE=$(date +%Y_%m)   # date au format 2025_04

print_h2 "Datapump Export Log Verification"

#  vérifier si une erreur ORA- est pésente dans les fichiers logs 
print_h3 "Checking for errors in the logs:"

if [ -z "${EXPDP_DIR}" ]; then
    echo "<pre>The EXPDP_DIR variable is not defined. Unable to verify Datapump logs.</pre>"
elif [ ! -d "${EXPDP_DIR}" ]; then
    echo "<pre>The directory EXPDP_DIR ('${EXPDP_DIR}') does not exist or is not accessible.</pre>"
else
    RESULT=$(find "${EXPDP_DIR}" -iname "export_*.log" -exec grep -H "ORA-" "{}" \;)
    if [ -z "$RESULT" ]; then
        echo "<pre>No ORA- errors detected in the log files for the month ${CURRENT_DATE}.</pre>"
    else
        echo "<pre>$RESULT</pre>"
    fi

    # afficher les dernières lignes des fichiers log pour voir les les exports se sont bien déroulés
    print_h1 "Displaying the first 10 and last 10 lines of the log files"
    # préparation de la commande find : définition de la fonction d'affichage plus lisible
    show_log_excerpt() {
      local file="$1"
      echo "<br><h2>$(echo "${file}" | cut -d/ -f4)</h2>"    # affiche le nom de la base
      echo "<br><h3>${file}</h2>"           # affiche le nom du fichier en gras
      echo "<pre>"
      head -10 "$file"                      # affiche les 10 première lignes dans le bloc PRE
      echo "</pre><pre>" 
      tail -10 "$file"                      # affiche les 10 dernières lignes dans le bloc PRE
      echo "</pre>"
    }
    # export pour rendre la fonction accessible à bash -c
    export -f show_log_excerpt

    # find appelle la fonction en lui passant $0 comme paramètre
    find "${EXPDP_DIR}" -iname "export_*${CURRENT_DATE}*.log" -exec bash -c 'show_log_excerpt "$0"' {} \;
fi