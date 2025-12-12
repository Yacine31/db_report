#!/bin/bash

# ==============================================================================
# Script pour générer un rapport HTML unique avec les graphiques de sauvegarde
# RMAN pour toutes les bases de données détectées sur le serveur.
# ==============================================================================

# --- CONFIGURATION ---
# on prepare le fichier output
HTML_FILE="${OUTPUT_DIR}/RMAN_Chart_${HNAME}_${DATETIME}.html"

# HTML_FILE="rapport_rman_global.html"
SQL_SCRIPT="rman_chart/generate_rman_chart.sql"
# --- FIN CONFIGURATION ---

# Étape 1: Créer l'en-tête du fichier HTML
# echo "Initialisation du rapport : ${HTML_FILE}"
cat rman_chart/00_chart_html_header.html > "${HTML_FILE}"

# Étape 2: Découvrir et boucler sur chaque base de données active
for sid in $(ps -eaf | grep ora_pmon | grep -v grep | grep -v -e '-MGMTDB' -e 'APX' | cut -d '_' -f3 | sort); do
    # Configuration de l'environnement Oracle pour le SID en cours
    export ORAENV_ASK=NO
    export ORACLE_SID="$sid"
    . oraenv -s > /dev/null

    # Ajout du titre pour la section de cette base
    echo "<h2>Evolution de la sauvegardes RMAN pour la base : ${sid}</h2>" >> "${HTML_FILE}"

    # Exécution de sqlplus en injectant la définition de la variable &db_sid au début du script.
    # Cette méthode est très robuste et évite les problèmes de passage de paramètres.
    (echo "DEFINE db_sid = ${sid}"; cat "${SQL_SCRIPT}") | sqlplus -s / as sysdba >> "${HTML_FILE}"
done

# Étape 3: Finaliser le fichier HTML
cat rman_chart/99_chart_html_footer.html >> "${HTML_FILE}"

log_info "Génrération du graphique des sauvegardes RMAN dans ${HTML_FILE}"