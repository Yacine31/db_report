prompt <h2>Détail des datafiles : </h2>


COL file_id HEAD "File ID"
COL file_name HEAD "Datafile"
COL tablespace_name FORMAT A20 HEAD "Tablespace"

COL file_size_mb FORMAT 999999999.00 HEAD "File Size MB"
COL space_used_mb FORMAT 999999999.00 HEAD "Space Used MB"
COL space_free_mb FORMAT 999999999.00 HEAD "Space Free MB"
COL maxsize_mb FORMAT 999999999.00 HEAD "Max Size MB"
COL percent_used FORMAT 999.00 HEAD "% Used"

COL autoextensible FORMAT A15 HEAD "Auto Extensible"
COL status head "Status"
COL online_status format a15 head "Online Status"

select
    d.file_id,
    d.file_name,
    d.tablespace_name,
    a.bytes_alloc/1024/1024 file_size_mb,
    (a.bytes_alloc - nvl(b.bytes_free, 0))/1024/1024 space_used_mb,
    nvl(b.bytes_free, 0)/1024/1024  space_free_mb,
    a.maxbytes/1024/1024 maxsize_mb,
    round((a.bytes_alloc - nvl(b.bytes_free, 0)) / a.maxbytes * 100,2) percent_used,
    d.autoextensible,
    d.status,
    d.online_status
from
    (
        select
            f.file_id,
            sum(f.bytes) bytes_alloc,
            sum(decode(f.autoextensible, 'YES', f.maxbytes, 'NO', f.bytes)) maxbytes
        from dba_data_files f group by file_id
    ) a,
    (
        select
            f.file_id,
            sum(f.bytes) bytes_free
        from dba_free_space f group by file_id
    ) b,
    dba_data_files d
where
    a.file_id = b.file_id (+) and d.file_id=a.file_id
order by 
    d.file_name
;

prompt <h2>Existance de blocks corrompus :</h2>
select * from v$database_block_corruption;
