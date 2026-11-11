prompt <h2>Last Alert Log Errors</h2>

-- les messages peuvent contenir < > & : on les echappe
COL "Message" ENTMAP ON

-- tri AVANT le filtre ROWNUM pour garder les 50 erreurs les plus recentes
select /* db-html-report */
    *
FROM
    (
        SELECT
            TO_CHAR(ORIGINATING_TIMESTAMP, 'DD-MM-YYYY HH24:MI:SS') "Date",
            MESSAGE_TEXT                                          "Message"
        FROM
            X$DBGALERTEXT
        WHERE
            ORIGINATING_TIMESTAMP > SYSTIMESTAMP - 30
            AND REGEXP_LIKE(MESSAGE_TEXT, '(ORA-)')
        ORDER BY
            ORIGINATING_TIMESTAMP DESC
    )
WHERE
    ROWNUM <= 50;