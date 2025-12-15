prompt <h2>Redo Log Files</h2>

ALTER SESSION SET NLS_DATE_FORMAT='YYYY/MM/DD HH24:MI:SS';

select /* db-html-report */
    *
FROM
    V$LOG
ORDER BY
    GROUP#,
    THREAD#,
    SEQUENCE#;