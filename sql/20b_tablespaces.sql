prompt <h2>Détail des tablespaces (dans toutes les PDB si la base est CDB) : </h2>

COL NAME FORMAT A20 HEAD "DB/PDB NAME"
COL TABLESPACE_NAME FORMAT A20 HEAD "Tablespace"
COL alloc_mb FORMAT 99999999.00 HEAD "Allocated MB"
COL used_mb FORMAT 99999999.00 HEAD "Used MB"
COL free_mb FORMAT 99999999.00 HEAD "Free MB"
COL max_mb FORMAT 99999999.00 HEAD "MaxSize MB"
COL Pct_Used FORMAT 999.00 HEAD "% Used"
COL BIGFILE FORMAT A8 HEAD "Bigfile"

select /* db-html-report */  
    a.con_id,
    c.NAME,
    a.tablespace_name,
    t.bigfile,
    a.bytes_alloc/1024/1024 alloc_mb,
    (a.bytes_alloc - nvl(b.bytes_free, 0))/1024/1024 used_mb,
    (nvl(b.bytes_free, 0))/1024/1024  free_mb,
    maxbytes/1024/1024 Max_mb,
    (a.bytes_alloc - nvl(b.bytes_free, 0)) / maxbytes * 100 Pct_Used
from
    (
        select
            f.con_id,
            f.tablespace_name,
            sum(f.bytes) bytes_alloc,
            sum(decode(f.autoextensible, 'YES', f.maxbytes, 'NO', f.bytes)) maxbytes
        from
            cdb_data_files f
        group by
            con_id, tablespace_name
    ) a,
    (
        select
            f.con_id,
            f.tablespace_name,
            sum(f.bytes) bytes_free
        from
            cdb_free_space f
        group by
            con_id, tablespace_name
    ) b,
    v$containers c,
    cdb_tablespaces t
where
    a.con_id = b.con_id
    and a.con_id = c.con_id(+)
    and a.con_id = t.con_id
    and a.tablespace_name = b.tablespace_name (+)
    and a.tablespace_name = t.tablespace_name
order by 
    a.con_id, 
    c.NAME,
    a.tablespace_name
;