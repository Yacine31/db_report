-- db-report: requires-open
prompt <h2>Recycle Bin Content per Schema</h2>
-- Aucune ligne = corbeille vide.

COL "Oldest Drop" FORMAT A11

select /* db-html-report */
    c.name                                              "DB/PDB Name",
    r.owner                                             "Owner",
    count(*)                                            "Objects",
    round(sum(r.space * t.block_size) / 1024 / 1024)    "Size MB",
    to_char(min(to_date(r.droptime, 'YYYY-MM-DD:HH24:MI:SS')), 'YYYY/MM/DD') "Oldest Drop"
from cdb_recyclebin r
join cdb_tablespaces t
  on t.con_id = r.con_id and t.tablespace_name = r.ts_name
left join v$containers c on c.con_id = r.con_id
group by c.name, r.owner
order by 4 desc;
