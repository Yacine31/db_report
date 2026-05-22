prompt <h2>Data Guard — Archive Destinations (V$ARCHIVE_DEST_STATUS)</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

COL destination FORMAT A50 WRAPPED
COL db_unique_name FORMAT A20
COL error FORMAT A40 WRAPPED

select /* db-html-report */
    dest_id,
    dest_name,
    status,
    target,
    archiver,
    schedule,
    destination,
    db_unique_name,
    applied_seq#,
    error
from v$archive_dest_status
where status <> 'INACTIVE'
order by dest_id;
