DATETIME=$(date +%Y%m%d_%H%M)
HNAME=$(hostname)
DATE_REP=$(date +%Y_%m_%d)

for r in $(ps -eaf | grep pmon | egrep -v 'grep|ASM|APX1' | cut -d '_' -f3)
do
        export ORAENV_ASK=NO
        export ORACLE_SID=$r

        OUTPUT_DIR=output/${HNAME}/${ORACLE_SID}/${DATE_REP}
        mkdir -p ${OUTPUT_DIR}

        # export CSV_FILE=${OUTPUT_DIR}/Rapport_${HNAME}_${ORACLE_SID}_${DATETIME}.csv
        . oraenv -s > /dev/null

        DATE_JOUR=$(date +"%d/%m/%Y %Hh%M")
        
        # execution des scripts shell
        for f in sh/*.sh
        do
                CSV_FILE=${OUTPUT_DIR}/$(basename $f | sed 's/.sh$/.csv/g')
                /bin/sh $f > ${CSV_FILE}
        done

        # Si ASM, on exécute les scripts ASM
        if [ $(ps -ef | grep pmon | grep ASM | wc -l) -gt 0 ]; then
                for f in asm/*.sql
                do
                        CSV_FILE=${OUTPUT_DIR}/$(basename $f | sed 's/.sql$/.csv/g')
                        sed '1 s/^/SET PAGES 999 FEEDBACK OFF MARKUP CSV ON SPOOL ON PREFORMAT OFF ENTMAP OFF\n/' $f | grep -v "^prompt" | sqlplus -s / as sysdba > ${CSV_FILE}
                done
        fi

        # execution des scripts sql
        echo "<h1>Configuration de la base de données ${ORACLE_SID}</h1>" >> ${CSV_FILE}
        for f in sql/*.sql
        do
                CSV_FILE=${OUTPUT_DIR}/$(basename $f | sed 's/.sql$/.csv/g')
                sed '1 s/^/SET PAGES 999 FEEDBACK OFF MARKUP CSV ON SPOOL ON PREFORMAT OFF ENTMAP OFF\n/' $f | grep -v "^prompt" | sqlplus -s / as sysdba > ${CSV_FILE}
        done

        # suppression du zip s'il existe déjà
        rm -f ${HNAME}_${ORACLE_SID}_${DATE_REP}.zip 2>/dev/null
        # compression pour récupérer la totalité en zip
        zip -r ${HNAME}_${ORACLE_SID}_${DATE_REP}.zip ${OUTPUT_DIR} 1>/dev/null

        echo Les fichiers CSV sont dans le répertoire : ${OUTPUT_DIR}
        echo Pour récupérer les fichiers dans un seul zip :  ${HNAME}_${ORACLE_SID}_${DATE_REP}.zip
done
