#!/bin/bash

# ==============================================================================
# Script pour générer un rapport HTML unique avec les graphiques de sauvegarde
# RMAN pour toutes les bases de données détectées sur le serveur.
# ==============================================================================

# --- CONFIGURATION ---
HTML_FILE="rapport_rman_global.html"
SQL_SCRIPT="summary/24_rman_chart.sql"
# --- FIN CONFIGURATION ---

# Étape 1: Créer l'en-tête du fichier HTML
echo "Initialisation du rapport : ${HTML_FILE}"
cat html/01_html_chart_header.html > "${HTML_FILE}"

# Étape 2: Découvrir et boucler sur chaque base de données active
echo "Découverte des bases de données via les processus 'pmon'..."
for sid in $(ps -eaf | grep ora_pmon | grep -v grep | grep -v -e '-MGMTDB' -e 'APX' | cut -d '_' -f3 | sort); do
    echo " - Traitement de la base : ${sid}"

    # Configuration de l'environnement Oracle pour le SID en cours
    export ORAENV_ASK=NO
    export ORACLE_SID="$sid"
    . oraenv -s > /dev/null

    # Ajout du titre pour la section de cette base
    echo "<h2>Sauvegardes RMAN pour la base : ${sid}</h2>" >> "${HTML_FILE}"

    # Exécution de sqlplus et ajout du fragment (JS + div) au fichier HTML
    # L'argument "$sid" est passé au script SQL et sera utilisé pour remplacer "&1"
    sqlplus -s / as sysdba @"${SQL_SCRIPT}" "${sid}" >> "${HTML_FILE}"

done

# Étape 3: Finaliser le fichier HTML
echo "Finalisation du rapport."
cat html/98_html_chart_footer.html >> "${HTML_FILE}"

echo "Terminé ! Le rapport est disponible ici : ${HTML_FILE}"