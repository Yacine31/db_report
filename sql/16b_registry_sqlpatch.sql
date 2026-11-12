-- db-report: requires-open
prompt <h2>SQL Patches Applied in the Database (DBA_REGISTRY_SQLPATCH)</h2>
-- A comparer avec "opatch lspatches" du rapport serveur :
-- un patch present dans le home mais absent ici = datapatch non execute.
alter session set nls_timestamp_format='YYYY/MM/DD HH24:MI:SS';

COL description ENTMAP ON

select /* db-html-report */
    patch_id,
    action,
    status,
    action_time,
    description
from dba_registry_sqlpatch
order by action_time;
