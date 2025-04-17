#!/bin/bash
# script pour vérifier les logs des fichiers datapump et voir si des erreurs sont présentes

EXPDP_DIR="/u04/expdp"
CURRENT_DATE=$(date +%Y_%m)   # date au format 2025_04

echo "<h2>Vérification des logs des exports Datapump</h2>"

#  vérifier si une erreur ORA- est pésente dans les fichiers logs 
echo "<h3>Vérification de la présence d'erreurs dans les logs :</h3>"
RESULT=$(find "${EXPDP_DIR}" -iname "export*${CURRENT_DATE}*log" -exec grep -H "ORA-" "{}" \;)
if [ -z "$RESULT" ]; then
    echo "<pre>Aucune erreur ORA- détectée dans les fichiers logs du mois ${CURRENT_DATE}.<pre>"
else
    echo "<pre>$RESULT<pre>"
fi

# afficher les dernières lignes des fichiers log pour voir les les exports se sont bien déroulés
echo "<h3>Vérification des dernières lignes dans les logs :</h3>"
echo "<pre>"
find "${EXPDP_DIR}" -iname "export*${CURRENT_DATE}*log" -exec bash -c 'echo "--- {} ---"; tail -3 "{}"' \;
echo "</pre>"
