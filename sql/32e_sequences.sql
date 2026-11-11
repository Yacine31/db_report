prompt <h2>Sequences Above 80% of Their Maximum Value</h2>
-- Sequences croissantes sans CYCLE des schemas applicatifs. Aucune ligne = aucune sequence proche de sa limite.

select /* db-html-report */
    c.name                                          "DB/PDB Name",
    s.sequence_owner,
    s.sequence_name,
    to_char(s.last_number)                          last_number,
    to_char(s.max_value)                            max_value,
    s.increment_by,
    round(s.last_number / s.max_value * 100, 2)     "% Used"
from cdb_sequences s
join cdb_users u
  on u.con_id = s.con_id and u.username = s.sequence_owner and u.oracle_maintained = 'N'
left join v$containers c on c.con_id = s.con_id
where s.cycle_flag = 'N'
  and s.increment_by > 0
  and s.max_value > 0
  and s.last_number / s.max_value > 0.8
order by 7 desc;
