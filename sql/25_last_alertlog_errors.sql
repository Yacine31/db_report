prompt <h2>Les dernières erreurs de la base de données (Les 30 derniers jours et les 50 dernières lignes)</h2>

select /* axiome */
    TO_CHAR(ORIGINATING_TIMESTAMP, 'DD-MM-YYYY HH24:MM:SS') "Date",
    MESSAGE_TEXT                                          "Message"
FROM
    X$DBGALERTEXT
WHERE
    ORIGINATING_TIMESTAMP > SYSTIMESTAMP - 30
    AND REGEXP_LIKE(MESSAGE_TEXT, '(ORA-)')
    AND ROWNUM <=50
ORDER BY
    ORIGINATING_TIMESTAMP DESC;