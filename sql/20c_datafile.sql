prompt <h2>CDB/PDB - Détail des datafiles : </h2>

WITH
-- Sous-requête pour les fichiers de données dans une CDB
cdb_files AS (
    (
        select
            p.con_id AS pdb_id,
            p.pdb_name AS pdb_name,
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
            dba_data_files d, cdb_pdbs p
        where
            a.file_id = b.file_id (+) and d.file_id=a.file_id and d.pdb_id=p.con_id
        order by 
            p.con_id, p.pdb_name, d.file_name
    )    
    WHERE 
        (SELECT cdb AS is_cdb FROM v$database) = 'YES'
),
-- Sous-requête pour les fichiers de données dans une non-CDB
non_cdb_files AS (
    (
        select
            NULL AS pdb_id,
            NULL AS pdb_name,
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
    )    
    WHERE 
        (SELECT cdb AS is_cdb FROM v$database) = 'NO'
)
-- Requête finale combinant les résultats des sous-requêtes
SELECT * FROM cdb_files
UNION ALL
SELECT * FROM non_cdb_files;