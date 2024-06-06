prompt <h2>CDB/PDB - Détail des datafiles : </h2>

WITH
-- Sous-requête pour les fichiers de données dans une CDB
cdb_files AS (
    -- cdb_files.sql
    SELECT
        p.con_id AS pdb_id,
        p.pdb_name AS pdb_name,
        d.file_id,
        d.tablespace_name,
        d.file_name,
        a.bytes_alloc/1024/1024 AS file_size_mb,
        (a.bytes_alloc - NVL(b.bytes_free, 0))/1024/1024 AS space_used_mb,
        NVL(b.bytes_free, 0)/1024/1024 AS space_free_mb,
        a.maxbytes/1024/1024 AS maxsize_mb,
        ROUND((a.bytes_alloc - NVL(b.bytes_free, 0)) / a.maxbytes * 100, 2) AS percent_used,
        d.autoextensible,
        d.status,
        d.online_status
    FROM
        (
            SELECT
                f.file_id,
                SUM(f.bytes) AS bytes_alloc,
                SUM(DECODE(f.autoextensible, 'YES', f.maxbytes, 'NO', f.bytes)) AS maxbytes
            FROM cdb_data_files f GROUP BY file_id
        ) a
        LEFT JOIN (
            SELECT
                f.file_id,
                SUM(f.bytes) AS bytes_free
            FROM cdb_free_space f GROUP BY file_id
        ) b ON a.file_id = b.file_id
        JOIN cdb_data_files d ON a.file_id = d.file_id
        JOIN cdb_pdbs p ON d.con_id = p.pdb_id
    WHERE 
        (SELECT cdb FROM v$database) = 'YES'
),
-- Sous-requête pour les fichiers de données dans une non-CDB
non_cdb_files AS (
    -- non_cdb_files.sql
    SELECT
        NULL AS pdb_id,
        NULL AS pdb_name,
        d.file_id,
        d.tablespace_name,
        d.file_name,
        a.bytes_alloc/1024/1024 AS file_size_mb,
        (a.bytes_alloc - NVL(b.bytes_free, 0))/1024/1024 AS space_used_mb,
        NVL(b.bytes_free, 0)/1024/1024 AS space_free_mb,
        a.maxbytes/1024/1024 AS maxsize_mb,
        ROUND((a.bytes_alloc - NVL(b.bytes_free, 0)) / a.maxbytes * 100, 2) AS percent_used,
        d.autoextensible,
        d.status,
        d.online_status
    FROM
        (
            SELECT
                f.file_id,
                SUM(f.bytes) AS bytes_alloc,
                SUM(DECODE(f.autoextensible, 'YES', f.maxbytes, 'NO', f.bytes)) AS maxbytes
            FROM dba_data_files f GROUP BY file_id
        ) a
        LEFT JOIN (
            SELECT
                f.file_id,
                SUM(f.bytes) AS bytes_free
            FROM dba_free_space f GROUP BY file_id
        ) b ON a.file_id = b.file_id
        JOIN dba_data_files d ON a.file_id = d.file_id
    WHERE 
        (SELECT cdb FROM v$database) = 'NO'
)
-- Requête finale combinant les résultats des sous-requêtes
SELECT * FROM cdb_files
    ORDER BY 
        p.pdb_id, d.tablespace_name, d.file_name
UNION ALL
SELECT * FROM non_cdb_files;
    ORDER BY 
        d.tablespace_name, d.file_name