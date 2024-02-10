prompt <h2>Fichiers de journalisation (Redolog) :</h2>

ALTER SESSION SET NLS_DATE_FORMAT='YYYY/MM/DD HH24:MI:SS';

SELECT
    *
FROM
    V$LOG
ORDER BY
    GROUP#,
    THREAD#,
    SEQUENCE#;