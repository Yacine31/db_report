COL con_id HEAD "con_id"
COL pdb_id HEAD "pdb_id"
COL pdb_name HEAD "pdb_name"
COL file_id HEAD "file_id"
COL file_name HEAD "file_name"
COL tablespace_name FORMAT A20 HEAD "tablespace"

COL file_size_mb FORMAT 999999999.00 HEAD "file_size_mb"
COL percent_used FORMAT 999.00 HEAD "percent_used"
COL space_used_mb FORMAT 999999999.00 HEAD "space_used_mb"
COL space_free_mb FORMAT 999999999.00 HEAD "space_free_mb"
COL maxsize_mb FORMAT 999999999.00 HEAD "maxsize_mb"

COL autoextensible FORMAT A15 HEAD "autoextensible"
COL status head "status"
COL online_status format a15 head "online_status"

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
        ROUND((a.bytes_alloc - NVL(b.bytes_free, 0)) / a.maxbytes * 100, 2) AS percent_used,
        (a.bytes_alloc - NVL(b.bytes_free, 0))/1024/1024 AS space_used_mb,
        NVL(b.bytes_free, 0)/1024/1024 AS space_free_mb,
        a.maxbytes/1024/1024 AS maxsize_mb,
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
        RIGHT JOIN cdb_pdbs p ON d.con_id = p.pdb_id
    WHERE 
        (SELECT cdb FROM v$database) = 'YES'
    ORDER BY p.pdb_id, d.tablespace_name, d.file_name
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
        ROUND((a.bytes_alloc - NVL(b.bytes_free, 0)) / a.maxbytes * 100, 2) AS percent_used,
        (a.bytes_alloc - NVL(b.bytes_free, 0))/1024/1024 AS space_used_mb,
        NVL(b.bytes_free, 0)/1024/1024 AS space_free_mb,
        a.maxbytes/1024/1024 AS maxsize_mb,
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
    ORDER BY d.tablespace_name, d.file_name
)
-- Requête finale combinant les résultats des sous-requêtes
SELECT * FROM cdb_files
UNION ALL
SELECT * FROM non_cdb_files;
