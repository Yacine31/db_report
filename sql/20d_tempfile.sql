prompt <h2>Détail des tempfile : </h2>

COL con_id HEAD "CON ID"
COL name HEAD "PDB Name"
COL file_id HEAD "File ID"
COL tablespace_name FORMAT A20 HEAD "Tablespace"
COL file_name HEAD "Tempfile"
COL status head "Status"
COL file_size_mb FORMAT 999999999.00 HEAD "File Size MB"
COL maxsize_mb FORMAT 999999999.00 HEAD "Max Size MB"
COL autoextensible FORMAT A15 HEAD "Auto Extensible"

select 
    t.con_id,
    c.name,
    t.file_id, 
    t.tablespace_name,
    t.file_name, 
    t.status,
    round(t.bytes/1024/1024) file_size_mb, 
    round(t.maxbytes/1024/1024) maxsize_mb, 
    t.autoextensible
from cdb_temp_files t, v$containers c
where t.con_id = c.con_id
order by t.con_id, t.file_id, t.file_name;