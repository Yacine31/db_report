#!/bin/bash
# Ce script exécute des sql pour fournir une vue global de certains aspect de la base
# tous les datafiles, toutes les sauvegardes, toutes les erreur dans alertlog, ...
export LANG=en_US
DATETIME=`date +%Y%m%d%H%M`
HNAME=$(hostname)
OUTPUT_DIR=output/$(date +%Y%m%d)
mkdir -p ${OUTPUT_DIR}


# Execution des scripts sql
for sqlfile in summary/*.sql
do
    # on prepare le fichier output
    FILENAME=$(basename "$sqlfile" | cut -d_ -f2)
    BASENAME="${FILENAME%.*}"
    HTML_FILE=${OUTPUT_DIR}/Summary_${BASENAME}_${HNAME}_${DATETIME}.html
    # insertion du header HTML
    cat html/00_html_header.html >> ${HTML_FILE}

    for sid in $(ps -eaf | grep pmon | egrep -v 'grep|ASM|APX1' | cut -d '_' -f3)
    do
            export ORAENV_ASK=NO
            export ORACLE_SID=$sid
            . oraenv -s > /dev/null

            # ajout du nom de la base
            echo '<h3>Base de données : '$sid'</h3>' >> ${HTML_FILE}
            # ajouter le resultat du script sql dans la page html
            cat summary/01_sql_header.txt $sqlfile | sqlplus -s / as sysdba >> ${HTML_FILE}
    done

    # insertion du footer HTML
    cat html/99_html_footer.html >> ${HTML_FILE}

    echo Rapport synthèse pour ${FILENAME} dans : ${HTML_FILE}
done