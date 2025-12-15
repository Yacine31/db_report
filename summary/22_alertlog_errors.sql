prompt <h3>Last Alertlog Errors</h3>

SELECT /* db-html-report */
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