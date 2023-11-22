prompt <h2>Détail des tablespaces : </h2>
COL TABLESPACE_NAME FORMAT A20 HEAD "Nom Tablespace"
COL PCT_OCCUPATION_THEORIQUE FORMAT 990.00 HEAD "% Occup"
COL TAILLE_MIB FORMAT 99999990.00 HEAD "Taille MB"
COL TAILLE_MAX_MIB FORMAT 99999990.00 HEAD "Taille max MB"
COL TAILLE_OCCUPEE_MIB FORMAT 99999990.00 HEAD "Espace occupé MiB"
-- WITH TS_FREE_SPACE AS
-- (select tablespace_name, file_id, sum(bytes) FREE_O from dba_free_space group by tablespace_name, file_id
-- ), TEMP_ALLOC AS
-- (select tablespace_name, file_id, sum(bytes) USED_O from v$temp_extent_map group by tablespace_name, file_id
-- )
-- SELECT
--   TABLESPACE_NAME,
--   SUM(TAILLE_MIB) TAILLE_MIB,
--   SUM(TAILLE_MAX_MIB) TAILLE_MAX_MIB,
--   SUM(TAILLE_OCCUPEE_MIB) TAILLE_OCCUPEE_MIB,
--   ROUND(SUM(TAILLE_OCCUPEE_MIB)*100/SUM(GREATEST(TAILLE_MAX_MIB,TAILLE_MIB)),2) PCT_OCCUPATION_THEORIQUE
-- FROM
-- (
--     SELECT D.FILE_NAME, D.TABLESPACE_NAME, D.BYTES/1024/1024 TAILLE_MIB, DECODE(D.AUTOEXTENSIBLE,'NO',D.BYTES,D.MAXBYTES)/1024/1024 TAILLE_MAX_MIB,
--       (D.BYTES-FO.FREE_O)/1024/1024 TAILLE_OCCUPEE_MIB
--     FROM
--       DBA_DATA_FILES D, TS_FREE_SPACE FO
--     WHERE
--         D.TABLESPACE_NAME=FO.TABLESPACE_NAME
--     AND D.FILE_ID=FO.FILE_ID
--     UNION ALL
--     SELECT T.FILE_NAME, T.TABLESPACE_NAME, T.BYTES/1024/1024 TAILLE_MIB, DECODE(T.AUTOEXTENSIBLE,'NO',T.BYTES,T.MAXBYTES)/1024/1024 TAILLE_MAX_MIB,
--       (TA.USED_O)/1024/1024 TAILLE_OCCUPEE_MIB
--     FROM
--       DBA_TEMP_FILES T, TEMP_ALLOC TA
--     WHERE
--         T.TABLESPACE_NAME=TA.TABLESPACE_NAME
--     AND T.FILE_ID=TA.FILE_ID
-- )
-- GROUP BY TABLESPACE_NAME
-- ORDER BY TABLESPACE_NAME;-- 

COL TABLESPACE_NAME FORMAT A20 HEAD "Tablespace"
COL Allocated FORMAT 99999990.00 HEAD "Allocated MB"
COL Used FORMAT 99999990.00 HEAD "Used MB"
COL Free FORMAT 99999990.00 HEAD "Freed MB"
COL Max FORMAT 99999990.00 HEAD "MaxSize MB"
COL Pct_Used FORMAT 990.00 HEAD "% Used"

select
    a.tablespace_name,
    a.bytes_alloc alloc,
    a.bytes_alloc - nvl(b.bytes_free, 0) used,
    nvl(b.bytes_free, 0)  free,
    maxbytes Max,
    (a.bytes_alloc - nvl(b.bytes_free, 0)) / maxbytes * 100 Pct_Used
from
    (
        select
            f.tablespace_name,
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
    sum(h.bytes_free + h.bytes_used) alloc,
    sum(nvl(p.bytes_used, 0)) used,
    sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) free,
    sum(f.maxbytes) max,
    (sum(h.bytes_free + h.bytes_used) - sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0))) / sum(f.maxbytes) "Pct_Used%Max"
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
    dt.contents
order by
    1
;
