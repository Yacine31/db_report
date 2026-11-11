-- Dernieres erreurs ORA- de l'alert log sur 30 jours (le rapport est prevu pour une execution mensuelle).
-- Requete commune a sql/25_last_alertlog_errors.sql (rapport de base) et summary/22_alertlog_errors.sql (page Summary) :
-- le titre de section reste dans le script appelant.

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
            ORIGINATING_TIMESTAMP > SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY')
            AND REGEXP_LIKE(MESSAGE_TEXT, '(ORA-)')
        ORDER BY
            ORIGINATING_TIMESTAMP DESC
    )
WHERE
    ROWNUM <= 50;
