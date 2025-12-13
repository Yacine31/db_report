prompt <h2>Who is connected ? </h2>

col PROGRAM for a35
col MACHINE for a20
col OSUSER for a10

ALTER SESSION SET NLS_DATE_FORMAT='YYYY/MM/DD HH24:MI:SS';

select /* db-html-report */
    OSUSER,
    MACHINE,
    PROGRAM,
    STATE,
    LOGON_TIME,
    EVENT
FROM
    V$SESSION
ORDER BY
    LOGON_TIME ASC;