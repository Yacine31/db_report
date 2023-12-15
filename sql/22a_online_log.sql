prompt <h2>Fichiers de journalisation (Redolog) :</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

SELECT
    *
FROM
    v$log
ORDER BY
    group#,
    thread#,
    sequence#;


