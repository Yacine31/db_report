prompt <h2>Database Links (DBA_DB_LINKS)</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

COL owner    FORMAT A20
COL db_link  FORMAT A40
COL username FORMAT A30
COL host     FORMAT A60 WRAPPED ENTMAP ON

select /* db-html-report */
    owner,
    db_link,
    username,
    host,
    created
from dba_db_links
order by owner, db_link;
