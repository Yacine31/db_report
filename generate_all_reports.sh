#!/bin/bash

# ==============================================================================
# Script pour générer un rapport HTML unique avec les graphiques de sauvegarde
# RMAN pour toutes les bases de données détectées sur le serveur.
# ==============================================================================

# --- CONFIGURATION ---
HTML_FILE="rapport_rman_global.html"
SQL_SCRIPT="generate_chart_data.sql"
# --- FIN CONFIGURATION ---

# Étape 1: Créer l'en-tête du fichier HTML
echo "Initialisation du rapport : ${HTML_FILE}"
cat html_header.html > "${HTML_FILE}"

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

    # Exécution de sqlplus en injectant la définition de la variable &db_sid au début du script.
    # Cette méthode est très robuste et évite les problèmes de passage de paramètres.
    (echo "DEFINE db_sid = ${sid}"; cat "${SQL_SCRIPT}") | sqlplus -s / as sysdba >> "${HTML_FILE}"

done

# Étape 3: Finaliser le fichier HTML
echo "Finalisation du rapport."
cat html_footer.html >> "${HTML_FILE}"

echo "Terminé ! Le rapport est disponible ici : ${HTML_FILE}"