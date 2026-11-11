-- Datafiles par conteneur (CDB) ou de la base (non-CDB).
-- Requete commune a sql/20c_datafile.sql (rapport de base) et summary/20_datafile.sql (page Summary) :
-- le titre de section reste dans le script appelant.

COL con_id HEAD "CON ID"
COL pdb_name HEAD "PDB Name"
COL file_id HEAD "File ID"
COL file_name HEAD "Datafile"
COL tablespace_name FORMAT A20 HEAD "Tablespace"

COL file_size_mb FORMAT 999999999 HEAD "File Size MB"
COL space_used_mb FORMAT 999999999 HEAD "Space Used MB"
COL space_free_mb FORMAT 999999999 HEAD "Space Free MB"
COL maxsize_mb FORMAT 999999999 HEAD "Max Size MB"
COL percent_used FORMAT 999.00 HEAD "% Used"

COL autoextensible FORMAT A15 HEAD "Auto Extensible"
COL status head "Status"
COL online_status format a15 head "Online Status"

WITH
-- CDB : un datafile par ligne, avec son conteneur. V$CONTAINERS contient CDB$ROOT,
-- contrairement a CDB_PDBS ; PDB$SEED est exclu (CDB_DATA_FILES n'expose pas ses fichiers).
-- Les file_id sont rapproches par conteneur (con_id, file_id).
cdb_files AS (
    SELECT /* db-html-report */
        c.con_id,
        c.name AS pdb_name,
        d.file_id,
        d.tablespace_name,
        d.file_name,
        a.bytes_alloc/1024/1024 AS file_size_mb,
        (a.bytes_alloc - NVL(b.bytes_free, 0))/1024/1024 AS space_used_mb,
        NVL(b.bytes_free, 0)/1024/1024 AS space_free_mb,
        a.maxbytes/1024/1024 AS maxsize_mb,
        ROUND((a.bytes_alloc - NVL(b.bytes_free, 0)) / NULLIF(a.maxbytes, 0) * 100, 2) AS percent_used,
        d.autoextensible,
        d.status,
        d.online_status
    FROM
        (
            SELECT con_id, file_id,
                   SUM(bytes) AS bytes_alloc,
                   SUM(DECODE(autoextensible, 'YES', maxbytes, 'NO', bytes)) AS maxbytes
            FROM cdb_data_files
            GROUP BY con_id, file_id
        ) a
        LEFT JOIN (
            SELECT con_id, file_id, SUM(bytes) AS bytes_free
            FROM cdb_free_space
            GROUP BY con_id, file_id
        ) b ON b.con_id = a.con_id AND b.file_id = a.file_id
        JOIN cdb_data_files d ON d.con_id = a.con_id AND d.file_id = a.file_id
        JOIN v$containers c ON c.con_id = d.con_id
    WHERE
        (SELECT cdb FROM v$database) = 'YES'
        AND c.name <> 'PDB$SEED'
),
-- Non-CDB : les datafiles de la base, sans conteneur
non_cdb_files AS (
    SELECT /* db-html-report */
        NULL AS con_id,
        NULL AS pdb_name,
        d.file_id,
        d.tablespace_name,
        d.file_name,
        a.bytes_alloc/1024/1024 AS file_size_mb,
        (a.bytes_alloc - NVL(b.bytes_free, 0))/1024/1024 AS space_used_mb,
        NVL(b.bytes_free, 0)/1024/1024 AS space_free_mb,
        a.maxbytes/1024/1024 AS maxsize_mb,
        ROUND((a.bytes_alloc - NVL(b.bytes_free, 0)) / NULLIF(a.maxbytes, 0) * 100, 2) AS percent_used,
        d.autoextensible,
        d.status,
        d.online_status
    FROM
        (
            SELECT file_id,
                   SUM(bytes) AS bytes_alloc,
                   SUM(DECODE(autoextensible, 'YES', maxbytes, 'NO', bytes)) AS maxbytes
            FROM dba_data_files
            GROUP BY file_id
        ) a
        LEFT JOIN (
            SELECT file_id, SUM(bytes) AS bytes_free
            FROM dba_free_space
            GROUP BY file_id
        ) b ON b.file_id = a.file_id
        JOIN dba_data_files d ON d.file_id = a.file_id
    WHERE
        (SELECT cdb FROM v$database) = 'NO'
)
SELECT * FROM cdb_files
UNION ALL
SELECT * FROM non_cdb_files
ORDER BY 1 NULLS LAST, 4, 5;
