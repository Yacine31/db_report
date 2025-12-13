prompt <h2>Détail des tablespaces : </h2>

COL TABLESPACE_NAME FORMAT A20 HEAD "Tablespace"
COL alloc FORMAT 99999999 HEAD "Allocated MB"
COL used FORMAT 99999999 HEAD "Used MB"
COL free FORMAT 99999999 HEAD "Free MB"
COL max FORMAT 99999999 HEAD "MaxSize MB"
COL Pct_Used FORMAT 999.00 HEAD "% Used"
COL nb_of_file FORMAT 999 HEAD "Nbr Of Files"

select /* db-html-report */
    a.tablespace_name,
    t.bigfile,
    a.nb_of_file,
    a.bytes_alloc/1024/1024 alloc,
    (a.bytes_alloc - nvl(b.bytes_free, 0))/1024/1024 used,
    (nvl(b.bytes_free, 0))/1024/1024  free,
    maxbytes/1024/1024 Max,
    (a.bytes_alloc - nvl(b.bytes_free, 0)) / maxbytes * 100 Pct_Used
from
    (
        select
            f.tablespace_name,
            count(*) as nb_of_file,
            sum(f.bytes) bytes_alloc,
            sum(decode(f.autoextensible, 'YES', f.maxbytes, 'NO', f.bytes)) maxbytes
        from
            dba_data_files f
        group by
            tablespace_name
    ) a,
    (
        select
            f.tablespace_name,
            sum(f.bytes) bytes_free
        from
            dba_free_space f
        group by
            tablespace_name
    ) b,
    dba_tablespaces t
where
    a.tablespace_name = b.tablespace_name (+)
    and b.tablespace_name = t.tablespace_name
union all
select
    h.tablespace_name,
    dt.bigfile,
    count(*) as nb_of_file,
    (sum(h.bytes_free + h.bytes_used))/1024/1024 alloc,
    (sum(nvl(p.bytes_used, 0)))/1024/1024 used,
    (sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)))/1024/1024 free,
    (sum(f.maxbytes))/1024/1024 max,
    (sum(h.bytes_free + h.bytes_used) - sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0))) / sum(f.maxbytes) Pct_Used
from
    sys.v_$temp_space_header h,
    sys.v_$temp_extent_pool p,
    dba_temp_files f,
    dba_tablespaces dt
where
    p.file_id(+) = h.file_id
    and p.tablespace_name(+) = h.tablespace_name
    and f.file_id = h.file_id
    and f.tablespace_name = h.tablespace_name
    and h.tablespace_name = dt.tablespace_name
group by
    h.tablespace_name,
    dt.contents,
    dt.bigfile
order by
    1
;
