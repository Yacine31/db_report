prompt <h2>Data Guard — Apply/Receive Processes (V$MANAGED_STANDBY)</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

select /* db-html-report */
    process,
    pid,
    status,
    thread#,
    sequence#,
    block#,
    blocks
from v$managed_standby
order by process, thread#;

prompt <h2>Data Guard — Lag Statistics (V$DATAGUARD_STATS)</h2>

select /* db-html-report */
    name,
    value,
    unit,
    time_computed
from v$dataguard_stats
order by name;
