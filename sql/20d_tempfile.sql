prompt <h2>Détail des tempfile : </h2>

COL con_id HEAD "CON ID"
COL pdb_name HEAD "PDB Name"
COL file_id HEAD "File ID"
COL file_name HEAD "Tempfile"
COL tablespace_name FORMAT A20 HEAD "Tablespace"

COL file_size_mb FORMAT 999999999.00 HEAD "File Size MB"
-- COL space_used_mb FORMAT 999999999.00 HEAD "Space Used MB"
-- COL space_free_mb FORMAT 999999999.00 HEAD "Space Free MB"
COL maxsize_mb FORMAT 999999999.00 HEAD "Max Size MB"
-- COL percent_used FORMAT 999.00 HEAD "% Used"

COL autoextensible FORMAT A15 HEAD "Auto Extensible"
COL status head "Status"
-- COL online_status format a15 head "Online Status"

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
        d.bytes/1024/1024 AS file_size_mb,
        d.maxbytes/1024/1024 AS maxsize_mb,
        d.autoextensible,
        d.status
    FROM
        cdb_temp_files d 
        JOIN cdb_pdbs p ON d.con_id = p.pdb_id
    WHERE 
        (SELECT cdb FROM v$database) = 'YES'
    ORDER BY p.pdb_id, d.tablespace_name, d.file_name
),
-- Sous-requête pour les fichiers de données dans une non-CDB
non_cdb_files AS (
    -- non_cdb_files.sql
    SELECT
        0 AS pdb_id,
        NULL AS pdb_name,
        d.file_id,
        d.tablespace_name,
        d.file_name,
        d.bytes/1024/1024 AS file_size_mb,
        d.maxbytes/1024/1024 AS maxsize_mb,
        d.autoextensible,
        d.status
    FROM
        dba_temp_files d 
    WHERE 
        (SELECT cdb FROM v$database) = 'NO'
    ORDER BY d.tablespace_name, d.file_name
)
-- Requête finale combinant les résultats des sous-requêtes
SELECT * FROM cdb_files
UNION ALL
SELECT * FROM non_cdb_files;
