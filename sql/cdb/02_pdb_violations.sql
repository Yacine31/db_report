-- db-report: requires-open
prompt <h2>PDB Plug-in Violations (not resolved)</h2>
-- Aucune ligne = aucune violation en attente.
alter session set nls_timestamp_format='YYYY/MM/DD HH24:MI:SS';

COL message ENTMAP ON
COL action ENTMAP ON

select /* db-html-report */
    name,
    cause,
    type,
    status,
    time,
    message,
    action
from pdb_plug_in_violations
where status <> 'RESOLVED'
order by name, time;
