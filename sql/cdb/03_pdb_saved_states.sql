prompt <h2>PDB Saved States (DBA_PDB_SAVED_STATES)</h2>
-- Une PDB absente de cette liste ne se rouvre pas automatiquement au redemarrage de la CDB
-- (sauf gestion par Grid Infrastructure / services).

COL "Current Open Mode" FORMAT A17

select /* db-html-report */
    p.con_id,
    p.name                              "PDB Name",
    p.open_mode                         "Current Open Mode",
    nvl(s.state, 'NOT SAVED')           "Saved State",
    s.instance_name
from v$pdbs p
left join dba_pdb_saved_states s on s.con_name = p.name
where p.name <> 'PDB$SEED'
order by p.con_id;
