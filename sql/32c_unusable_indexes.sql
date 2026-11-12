-- db-report: requires-open
prompt <h2>Unusable Indexes</h2>
-- Index, partitions et sous-partitions d'index a l'etat UNUSABLE.
-- Aucune ligne = aucun index inutilisable.

select /* db-html-report */
    c.name "DB/PDB Name", x.owner, x.index_name, x.partition_name, x.table_name, x.status
from (
    select con_id, owner, index_name, cast(null as varchar2(128)) partition_name, table_name, status
    from cdb_indexes
    where status = 'UNUSABLE'
    union all
    select p.con_id, p.index_owner, p.index_name, p.partition_name, i.table_name, p.status
    from cdb_ind_partitions p
    join cdb_indexes i
      on i.con_id = p.con_id and i.owner = p.index_owner and i.index_name = p.index_name
    where p.status = 'UNUSABLE'
    union all
    select s.con_id, s.index_owner, s.index_name, s.subpartition_name, i.table_name, s.status
    from cdb_ind_subpartitions s
    join cdb_indexes i
      on i.con_id = s.con_id and i.owner = s.index_owner and i.index_name = s.index_name
    where s.status = 'UNUSABLE'
) x
left join v$containers c on c.con_id = x.con_id
order by c.name, x.owner, x.index_name, x.partition_name;
