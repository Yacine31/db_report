#!/bin/bash
#------------------------------------------------------------------------------
# Ce script exécute des sql pour fournir une vue global de certains aspect de la base
# tous les datafiles, toutes les sauvegardes, toutes les erreur dans alertlog, ...
#------------------------------------------------------------------------------

# Importe les fonctions utilitaires
# Le chemin est relatif au script appelant (rapport_bdd.sh)
source "$(dirname "$0")/sh/utils.sh"

# Les variables DATETIME, HNAME, OUTPUT_DIR, et l'environnement .env sont déjà gérés par rapport_bdd.sh
# On s'assure que OUTPUT_DIR est défini
: "${OUTPUT_DIR:?OUTPUT_DIR not set by calling script}"
: "${DATETIME:?DATETIME not set by calling script}"
: "${HNAME:?HNAME not set by calling script}"

log_info "Début de l'exécution des scripts de synthèse."

#------------------------------------------------------------------------------
# Execution des scripts sql de synthèse
#------------------------------------------------------------------------------
for sqlfile in summary/*.sql
do
    # on prepare le fichier output
    FILENAME=$(basename "$sqlfile" | cut -d_ -f2)
    BASENAME="${FILENAME%.*}"
    HTML_FILE="${OUTPUT_DIR}/Summary_${BASENAME}_${HNAME}_${DATETIME}.html"

    log_info "Génération du rapport de synthèse SQL pour ${FILENAME} dans ${HTML_FILE}"

    # insertion du header HTML
    cat html/00_html_header.html > "${HTML_FILE}"

    for sid in $(ps -eaf | grep pmon | egrep -v 'grep|ASM|APX1' | cut -d '_' -f3)
    do
            export ORAENV_ASK=NO
            export ORACLE_SID="$sid"
            # shellcheck source=/dev/null
            . oraenv -s > /dev/null

            # ajout du nom de la base
            echo "<h2>Base de données : ${sid}</h2>" >> "${HTML_FILE}"
            # ajouter le resultat du script sql dans la page html
            # Utilise le sql_header.txt standard
            cat sql/sql_header.txt "$sqlfile" | sqlplus -s / as sysdba >> "${HTML_FILE}"
    done

    # insertion du footer HTML
    cat html/99_html_footer.html >> "${HTML_FILE}"
        log_info "Rapport synthèse pour ${FILENAME} généré."
        echo "<p><a href=\"#top\">Retour en haut de page</a></p>" >> "${HTML_FILE}"
    done
    
    #------------------------------------------------------------------------------
    # exécution des scripts dans sh/local si présents
    #------------------------------------------------------------------------------
    LOCAL_DIR="sh/local"
    
    if [ -d "$LOCAL_DIR" ]; then
        log_info "Détection du dossier local : ${LOCAL_DIR}"
        for shfile in "${LOCAL_DIR}"/*.sh
        do
            [ -f "$shfile" ] || continue
            # on prépare le fichier output
            FILENAME=$(basename "$shfile")
            BASENAME="${FILENAME%.*}"
            HTML_FILE="${OUTPUT_DIR}/Summary_${BASENAME}_${HNAME}_${DATETIME}.html"
            log_info "Génération du rapport de synthèse Shell pour ${FILENAME} dans ${HTML_FILE}"
            # insertion du header HTML
            cat html/00_html_header.html > "${HTML_FILE}"
            # Exécution du script local en utilisant run_and_print
            print_h2 "Résultat du script : ${FILENAME}" >> "${HTML_FILE}"
            # Le script shfile lui-même doit être exécuté, et il contient déjà ses propres print_h2/run_and_print
            # Donc, on l'exécute directement.
            bash "$shfile" >> "${HTML_FILE}"
            # insertion du footer HTML
            cat html/99_html_footer.html >> "${HTML_FILE}"
            log_info "Rapport synthèse pour ${FILENAME} généré."
            echo "<p><a href=\"#top\">Retour en haut de page</a></p>" >> "${HTML_FILE}"
        done
    else
        log_info "Aucun script local détecté dans ${LOCAL_DIR}."
    fi
    log_info "Fin de l'exécution des scripts de synthèse."