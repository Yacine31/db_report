prompt <h2>Data Guard — Archive Destinations (V$ARCHIVE_DEST_STATUS)</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

COL dest_name             FORMAT A20
COL type                  FORMAT A15
COL database_mode         FORMAT A15
COL recovery_mode         FORMAT A30
COL destination           FORMAT A100
COL db_unique_name        FORMAT A20
COL synchronized          FORMAT A12
COL gap_status            FORMAT A25
COL error                 FORMAT A100

select /* db-html-report */
    dest_id,
    dest_name,
    status,
    type,
    database_mode,
    recovery_mode,
    destination,
    db_unique_name,
    archived_seq#,
    applied_seq#,
    synchronized,
    gap_status,
    error
from v$archive_dest_status
where status <> 'INACTIVE'
order by dest_id;
