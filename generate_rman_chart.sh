#!/bin/bash

# ==============================================================================
# Script pour générer un rapport HTML unique avec les graphiques de sauvegarde
# RMAN pour toutes les bases de données détectées sur le serveur.
# Le graphique est un SVG tracé par du JavaScript embarqué dans la page :
# aucune dépendance externe, le rapport s'affiche hors ligne.
# ==============================================================================

# Importe les fonctions utilitaires
# Le chemin est relatif au script appelant (oracle_db_report.sh)
source "$(dirname "$0")/sh/utils.sh"

# --- CONFIGURATION ---
# on prepare le fichier output
HTML_FILE="${OUTPUT_DIR}/RMAN_Chart_${HNAME}_${DATETIME}.html"

SQL_SCRIPT="rman_chart/generate_rman_chart.sql"
# --- FIN CONFIGURATION ---

# Étape 1: Créer l'en-tête du fichier HTML
cat rman_chart/00_chart_html_header.html > "${HTML_FILE}"

# Étape 2: Boucler sur les bases à traiter
# DB_REPORT_SIDS est positionnée par oracle_db_report.sh (option -s) ; à défaut, toutes les bases actives
for sid in ${DB_REPORT_SIDS:-$(list_db_sids)}; do
    # Configuration de l'environnement Oracle pour le SID en cours
    export ORAENV_ASK=NO
    export ORACLE_SID="$sid"
    . oraenv -s > /dev/null

    # Ajout du titre pour la section de cette base
    echo "<h2>RMAN Backup Evolution for Database: ${sid}</h2>" >> "${HTML_FILE}"

    # Exécution de sqlplus en injectant la définition de la variable &db_sid au début du script.
    # Cette méthode est très robuste et évite les problèmes de passage de paramètres.
    (echo "DEFINE db_sid = ${sid}"; cat "${SQL_SCRIPT}") | sqlplus -s / as sysdba >> "${HTML_FILE}"
done

# Étape 3: Finaliser le fichier HTML
cat rman_chart/99_chart_html_footer.html >> "${HTML_FILE}"

log_info "Generating RMAN backup chart in ${HTML_FILE}"
