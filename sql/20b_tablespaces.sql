prompt <h2>Détail des tablespaces (dans toutes les PDB si la base est CDB) : </h2>

COL con_id HEAD "CON ID"
COL db_pdb_name HEAD "DB/PDB Name"
COL TABLESPACE_NAME FORMAT A20 HEAD "Tablespace"
COL bigfile FORMAT A10 HEAD "Bigfile"
COL allocated_mb FORMAT 99999999 HEAD "Allocated MB"
COL nbr_files FORMAT 99 HEAD "Nbr Of Files"
COL used_mb FORMAT 99999999 HEAD "Used MB"
COL free_mb FORMAT 99999999 HEAD "Free MB"
COL max_mb FORMAT 99999999 HEAD "MaxSize MB"
COL pct_used FORMAT 999.00 HEAD "% Used"


select /* db-html-report */
  a.con_id,
  c.NAME as db_pdb_name,
  a.tablespace_name,
  t.bigfile,
  a.nbr_files,
  a.bytes_alloc/1024/1024 allocated_mb,
  (a.bytes_alloc - nvl(b.bytes_free, 0))/1024/1024 used_mb,
  (nvl(b.bytes_free, 0))/1024/1024 free_mb, 
  maxbytes/1024/1024 max_mb,
  (a.bytes_alloc - nvl(b.bytes_free, 0)) / maxbytes * 100 pct_used
from
  (
    select
      f.con_id,
      f.tablespace_name,
      count(*) as nbr_files,
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
      count(*) as nbr_files,
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
