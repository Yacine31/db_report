#!/bin/bash
# script pour vérifier les logs des fichiers datapump et voir si des erreurs sont présentes

# Importe les fonctions utilitaires
source "$(dirname "$0")/../utils.sh"

# --- Script principal ---

# EXPDP_DIR="/u04/backup" : la variable d'environnement est chargée depuis le fichier .env

CURRENT_DATE=$(date +%Y_%m)   # date au format 2025_04

print_h2 "Vérification des logs des exports Datapump"

#  vérifier si une erreur ORA- est pésente dans les fichiers logs 
echo "<h3>Vérification de la présence d'erreurs dans les logs :</h3>"

if [ -z "${EXPDP_DIR}" ]; then
    echo "<pre>La variable EXPDP_DIR n'est pas définie. Impossible de vérifier les logs Datapump.</pre>"
elif [ ! -d "${EXPDP_DIR}" ]; then
    echo "<pre>Le répertoire EXPDP_DIR ('${EXPDP_DIR}') n'existe pas ou n'est pas accessible.</pre>"
else
    RESULT=$(find "${EXPDP_DIR}" -iname "export_*.log" -exec grep -H "ORA-" "{}" \;)
    if [ -z "$RESULT" ]; then
        echo "<pre>Aucune erreur ORA- détectée dans les fichiers logs du mois ${CURRENT_DATE}.</pre>"
    else
        echo "<pre>$RESULT</pre>"
    fi

    # afficher les dernières lignes des fichiers log pour voir les les exports se sont bien déroulés
    echo "<h1>Affichage des 10 premières et 10 dernières lignes des fichiers logs :</h1>"
    # préparation de la commande find : définition de la fonction d'affichage plus lisible
    show_log_excerpt() {
      local file="$1"
      echo "<br><h2>--- ${file} ---</h2> "    # affiche le nom du fichier en gras
      echo "<pre>"
      head -10 "$file"                      # affiche les 10 première lignes dans le bloc PRE
      echo "</pre><pre>" 
      tail -10 "$file"                      # affiche les 10 dernières lignes dans le bloc PRE
      echo "</pre>"
    }
    # export pour rendre la fonction accessible à bash -c
    export -f show_log_excerpt

    # find appelle la fonction en lui passant $0 comme paramètre
    find "${EXPDP_DIR}" -iname "export_*.log" -exec bash -c 'show_log_excerpt "$0"' {} \;
fi