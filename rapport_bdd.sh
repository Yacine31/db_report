export LANG=en_US.UTF-8
DATETIME=`date +%Y%m%d%H%M`
HNAME=$(hostname)
OUTPUT_DIR=output/$(date +%Y%m%d)
mkdir -p ${OUTPUT_DIR}

for r in $(ps -eaf | grep pmon | egrep -v 'grep|ASM|APX1' | cut -d '_' -f3)
do
        export ORAENV_ASK=NO
        export ORACLE_SID=$r
        export HTML_FILE=${OUTPUT_DIR}/Rapport_${HNAME}_${ORACLE_SID}_${DATETIME}.html
        . oraenv -s > /dev/null

        cat sql/00_html_header.html >> ${HTML_FILE}
        DATE_JOUR=$(date +"%d/%m/%Y %Hh%M")
        echo "<h1>Rapport de base de données ${ORACLE_SID} sur le serveur $HNAME </h1>
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

        # Si ASM, on exécute les scripts ASM
        if [ $(ps -ef | grep pmon | grep ASM | wc -l) -gt 0 ]; then
                echo "<h1>Configuration de l'instance ASM</h1>" >> ${HTML_FILE}
                for f in asm/*.sql
                do
                        # sed '1 s/^/SET PAGES 999 FEEDBACK OFF MARKUP HTML ON SPOOL ON PREFORMAT OFF ENTMAP OFF\n/' $f | sqlplus -s / as sysdba >> ${HTML_FILE}
                        cat asm/sql_header.txt $f | sqlplus -s / as sysdba >> ${HTML_FILE}
                done
        fi

        # execution des scripts sql
        echo "<h1>Configuration de la base de données ${ORACLE_SID}</h1>" >> ${HTML_FILE}
        for f in sql/*.sql
        do
                # sed '1 s/^/SET PAGES 999 FEEDBACK OFF MARKUP HTML ON SPOOL ON PREFORMAT OFF ENTMAP OFF\n/' $f | sqlplus -s / as sysdba >> ${HTML_FILE}
                cat sql/sql_header.txt $f | sqlplus -s / as sysdba >> ${HTML_FILE}
        done

        sed -i 's/<table.*>$/<table class="table table-striped">/g' ${HTML_FILE}

        cat sql/99_html_footer.html >> ${HTML_FILE}

        # coloriage des mots clé en rouge ou en vert
        for txt in INVALID FAILED NOARCHIVELOG OFFLINE MOUNTED
        do 
                sed -i "s#<td>${txt}</td>#<td style='color: red; background-color: yellow;'>${txt}</td>#g" ${HTML_FILE}
        done

        for txt in COMPLETED
        do 
                sed -i "s#<td>${txt}</td>#<td style='color: white; background-color: green;'>${txt}</td>#g" ${HTML_FILE}
        done

        echo Rapport dans le fichier html : ${HTML_FILE}
done
