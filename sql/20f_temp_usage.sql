-- db-report: requires-open
prompt <h2>Temp Tablespace — Current Usage (V$TEMPSEG_USAGE)</h2>

col username  format a20
col sql_id    format a15
col tablespace format a20
col segtype   format a10

-- Un tablespace temporaire utilise toujours la taille de bloc standard de la base (db_block_size)
select /* db-html-report */
    u.username,
    u.session_num,
    u.sql_id,
    u.tablespace,
    u.segtype,
    round(u.blocks * p.block_size / 1024 / 1024, 1) as size_mb
from v$tempseg_usage u
cross join (select to_number(value) block_size from v$parameter where name = 'db_block_size') p
order by u.blocks desc;
