prompt <h2>Les dernières erreurs ASM (Les 30 derniers jours et les 50 dernières lignes)</h2>

-- set pages 99
select to_char(ORIGINATING_TIMESTAMP, 'DD-MM-YYYY HH-MM-SS') "Date", message_text "Message"
FROM X$DBGALERTEXT
WHERE originating_timestamp > systimestamp - 30  
AND regexp_like(message_text, '(ORA-)')
AND rownum <=50
order by originating_timestamp desc;

