export LANG=en_US
DATETIME=`date +%Y%m%d%H%M`
HNAME=$(hostname)
OUTPUT_DIR=output/$(date +%Y%m%d)
mkdir -p ${OUTPUT_DIR}

HTML_FILE=${OUTPUT_DIR}/Summary_${HNAME}_${DATETIME}.html
DIV_ONGLETS=onglets.html
DIV_CONTENU=contenu.html
rm -f ${DIV_CONTENU} ${DIV_ONGLETS} 2>/dev/null

for sid in $(ps -eaf | grep pmon | egrep -v 'grep|ASM|APX1' | cut -d '_' -f3)
do
        export ORAENV_ASK=NO
        export ORACLE_SID=$sid
        . oraenv -s > /dev/null

        # ajouter la base dans le menu de la page html
        echo '<button class="tab-button px-4 py-2 text-sm font-medium text-blue-600 \
            border-b-2 border-blue-600" data-tab="tab1">'$sid'</button>' >> ${DIV_ONGLETS} 

        # ajouter le resultat du script sql dans la page html
        cat 01_sql_header.txt ../sql/20c_datafile.sql | sqlplus -s / as sysdba >> ${DIV_CONTENU}
done
# on ferme les DIV dans le menu html
echo '</div>' >> ${DIV_ONGLETS}

# on ferme les DIV dans le contenu des onglets
echo '</div>' >> ${DIV_CONTENU}

# on va concaténer les sources HTML dans une seule page
cat 00_header.html >> ${HTML_FILE}
cat ${DIV_ONGLETS} >> ${HTML_FILE}
cat ${DIV_CONTENU} >> ${HTML_FILE}
cat 99_footer.html >> ${HTML_FILE}

echo Rapport dans le fichier html : ${HTML_FILE}