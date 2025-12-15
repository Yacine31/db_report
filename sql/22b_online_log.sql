prompt <h2>Redo/Standby Log Multiplexing</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

COL MEMBER FORMAT A90 WRAPPED
BREAK ON GROUP# SKIP 1 ON THREAD# ON SEQUENCE# ON TAILLE_MIB ON "STATUS(ARCHIVED)"
select /* db-html-report */
    'OnlineLog'           t,
    g.group#,
    g.thread#,
    g.sequence#,
    g.bytes / 1024 / 1024 taille_mib,
    g.status || '(' || g.archived || ')' "STATUS(ARCHIVED)",
    f.member
FROM
    v$log     g,
    v$logfile f
WHERE
    g.group# = f.group#
UNION ALL
SELECT
    'StandbyLog',
    g.group#,
    g.thread#,
    g.sequence#,
    g.bytes / 1024 / 1024 taille_mib,
    g.status || '(' || g.archived || ')' "STATUS(ARCHIVED)",
    f.member
FROM
    v$standby_log g,
    v$logfile     f
WHERE
    g.group# = f.group#
ORDER BY
    1,
    3,
    4,
    2;

