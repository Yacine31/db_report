-- db-report: requires-open
-- Tablespaces temporaires et tempfiles, par conteneur (CDB) ou pour la base (non-CDB).
-- CDB_TEMP_FREE_SPACE / DBA_TEMP_FREE_SPACE ne sont pas utilisees : dans une CDB 19c, elles
-- multiplient la taille et l'espace alloue par le nombre de conteneurs (y compris depuis une PDB).
-- Tailles : CDB_TEMP_FILES ; espace utilise : V$SORT_SEGMENT (blocs du segment de tri, par conteneur).

prompt <h2>Temp Tablespaces</h2>

COL con_id HEAD "CON ID"
COL pdb_name HEAD "DB/PDB Name"
COL tablespace_name FORMAT A20 HEAD "Tablespace"
COL nbr_files FORMAT 999 HEAD "Nbr Of Files"
COL size_mb FORMAT 99999999 HEAD "Size MB"
COL used_mb FORMAT 99999999 HEAD "Used MB"
COL peak_used_mb FORMAT 99999999 HEAD "Peak Used MB"
COL max_mb FORMAT 99999999 HEAD "MaxSize MB"
COL pct_used_alloc FORMAT 999.00 HEAD "% Used (alloc)"
COL pct_used_max FORMAT 999.00 HEAD "% Used (max)"

select /* db-html-report */
    c.con_id,
    c.name                                                   as pdb_name,
    f.tablespace_name,
    count(*)                                                 as nbr_files,
    sum(f.bytes) / 1048576                                   as size_mb,
    nvl(s.used_blocks, 0) * t.block_size / 1048576           as used_mb,
    nvl(s.max_used_blocks, 0) * t.block_size / 1048576       as peak_used_mb,
    sum(decode(f.autoextensible, 'YES', greatest(f.maxbytes, f.bytes), f.bytes)) / 1048576 as max_mb,
    nvl(s.used_blocks, 0) * t.block_size / nullif(sum(f.bytes), 0) * 100 as pct_used_alloc,
    nvl(s.used_blocks, 0) * t.block_size
        / nullif(sum(decode(f.autoextensible, 'YES', greatest(f.maxbytes, f.bytes), f.bytes)), 0) * 100 as pct_used_max
from cdb_temp_files f
join v$containers c
  on c.con_id = f.con_id
join cdb_tablespaces t
  on t.con_id = f.con_id and t.tablespace_name = f.tablespace_name
left join v$sort_segment s
  on s.con_id = f.con_id and s.tablespace_name = f.tablespace_name
group by c.con_id, c.name, f.tablespace_name, t.block_size, s.used_blocks, s.max_used_blocks
order by c.con_id, f.tablespace_name;

prompt <p><i>Used MB: space used at report time. Peak Used MB: highest usage since the instance started. % Used (max): autoextend included.</i></p>

prompt <h2>Tempfiles</h2>

COL file_id HEAD "File ID"
COL file_name HEAD "Tempfile"
COL file_size_mb FORMAT 99999999 HEAD "File Size MB"
COL maxsize_mb FORMAT 99999999 HEAD "Max Size MB"
COL autoextensible FORMAT A15 HEAD "Auto Extensible"
COL status HEAD "Status"

select /* db-html-report */
    c.con_id,
    c.name                  as pdb_name,
    f.file_id,
    f.tablespace_name,
    f.file_name,
    f.bytes / 1048576       as file_size_mb,
    decode(f.autoextensible, 'YES', greatest(f.maxbytes, f.bytes), f.bytes) / 1048576 as maxsize_mb,
    f.autoextensible,
    f.status
from cdb_temp_files f
join v$containers c
  on c.con_id = f.con_id
order by c.con_id, f.tablespace_name, f.file_id;
