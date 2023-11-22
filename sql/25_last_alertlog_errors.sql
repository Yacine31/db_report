prompt <h2>Les dernières erreurs de la base de données (Les 30 derniers jours et les 100 dernières lignes)</h2>

set pages 99
select to_char(ORIGINATING_TIMESTAMP, 'DD-MM-YYYY HH-MM-SS') "Date", message_text "Message"
FROM X$DBGALERTEXT
WHERE originating_timestamp > systimestamp - 30  
AND regexp_like(message_text, '(ORA-)')
AND rownum <=100
order by originating_timestamp  desc;

