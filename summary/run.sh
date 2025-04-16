export LANG=en_US
DATETIME=`date +%Y%m%d%H%M`
HNAME=$(hostname)
OUTPUT_DIR=output/$(date +%Y%m%d)
mkdir -p ${OUTPUT_DIR}

HTML_FILE=${OUTPUT_DIR}/Summary_${HNAME}_${DATETIME}.html
DIV_CONTENU=contenu.html
rm -f ${DIV_CONTENU} 2>/dev/null

for sid in $(ps -eaf | grep pmon | egrep -v 'grep|ASM|APX1' | cut -d '_' -f3)
do
        export ORAENV_ASK=NO
        export ORACLE_SID=$sid
        . oraenv -s > /dev/null

        # ajouter le resultat du script sql dans la page html
        cat 01_sql_header.txt 20_datafile.sql | sqlplus -s / as sysdba >> ${DIV_CONTENU}
done

# on va concaténer les sources HTML dans une seule page
cat 00_header.html >> ${HTML_FILE}
sed -n '/<table>/,/<\/table>/p' ${DIV_CONTENU} >> ${HTML_FILE}
# cat ${DIV_CONTENU} >> ${HTML_FILE}
cat 99_footer.html >> ${HTML_FILE}

echo Rapport dans le fichier html : ${HTML_FILE}