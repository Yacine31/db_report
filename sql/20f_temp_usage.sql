prompt <h2>Temp Tablespace — Current Usage (V$TEMPSEG_USAGE)</h2>

col username  format a20
col sql_id    format a15
col tablespace format a20
col segtype   format a10

select /* db-html-report */
    username,
    session_num,
    sql_id,
    tablespace,
    segtype,
    round(blocks * 8192 / 1024 / 1024, 1) as size_mb
from v$tempseg_usage
order by blocks desc;
