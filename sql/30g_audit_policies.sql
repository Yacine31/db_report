-- db-report: requires-open
prompt <h2>Enabled Unified Audit Policies</h2>

COL entity_type FORMAT A11
COL success FORMAT A7
COL failure FORMAT A7

select /* db-html-report */
    *
from audit_unified_enabled_policies
order by policy_name;

prompt <h2>Audit Trail Size</h2>
-- SYS.AUD$ et SYS.FGA_LOG$ (audit classique), schema AUDSYS (audit unifie)

select /* db-html-report */
    c.name                              "DB/PDB Name",
    s.owner                             "Owner",
    case when s.owner = 'AUDSYS' then 'Unified audit trail' else s.segment_name end "Audit Trail",
    s.tablespace_name                   "Tablespace",
    round(sum(s.bytes) / 1024 / 1024)   "Size MB"
from cdb_segments s
left join v$containers c on c.con_id = s.con_id
where (s.owner = 'SYS' and s.segment_name in ('AUD$', 'FGA_LOG$'))
   or s.owner = 'AUDSYS'
group by c.name, s.owner,
         case when s.owner = 'AUDSYS' then 'Unified audit trail' else s.segment_name end,
         s.tablespace_name
order by c.name, 5 desc;
