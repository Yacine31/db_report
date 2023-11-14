DATETIME=`date +%Y%m%d%H%M`
HNAME=$(hostname)

for r in $(ps -eaf | grep pmon | egrep -v 'grep|APX1' | cut -d '_' -f3)
do
        export ORAENV_ASK=NO
        export ORACLE_SID=$r
        export HTML_FILE=Rapport_$HNAME_${ORACLE_SID}_${DATETIME}.html
        . oraenv -s > /dev/null

        cat sql/00_html_header.html >> ${HTML_FILE}
        DATE_JOUR=$(date +"%d/%m/%Y %Hh%M")
        echo "<h1>Rapport de base de données</h1>
        <h2>Date : ${DATE_JOUR}</h2>
        <h2>Hostname : $HNAME</h2>
        <h2>Base de données : ${ORACLE_SID}</h2>" >> ${HTML_FILE}
        echo "<br><br>" >> ${HTML_FILE}
        
        # execution des scripts shell
        echo "<h1>Configuration système</h1>" >> ${HTML_FILE}
        for f in sh/*.sh
        do
                /bin/sh $f >> ${HTML_FILE}
        done

        echo "<br><br>" >> ${HTML_FILE}
        # execution des scripts sql
        echo "<h1>Configuration de la base de données ${ORACLE_SID}</h1>" >> ${HTML_FILE}
        for f in sql/*.sql
        do
                sed '1 s/^/SET PAGES 999 FEEDBACK OFF MARKUP HTML ON SPOOL ON PREFORMAT OFF ENTMAP OFF\n/' $f | sqlplus -s / as sysdba >> ${HTML_FILE}
        done


        sed -i 's/<table.*>$/<table class="table table-striped">/g' ${HTML_FILE}

        cat sql/99_html_footer.html >> ${HTML_FILE}

        echo Rapport dans le fichier html : ${HTML_FILE}
done
