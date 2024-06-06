prompt <h2>CDB/PDB - Détail des datafiles : </h2>

COLUMN is_cdb NEW_VALUE is_cdb_var
SELECT cdb AS is_cdb FROM v$database;

SELECT 
    CASE 
        WHEN '&is_cdb_var' = 'YES' THEN p.con_id 
        ELSE NULL 
    END AS pdb_id,
    CASE 
        WHEN '&is_cdb_var' = 'YES' THEN p.name 
        ELSE NULL 
    END AS pdb_name,
    df.tablespace_name, 
    df.file_name, 
    df.bytes/1024/1024 AS Size_Mo, 
    df.maxbytes/1024/1024 AS Maxsize_Mo, 
    df.autoextensible
FROM 
    cdb_data_files df
    LEFT JOIN cdb_pdbs p ON df.con_id = p.con_id
WHERE '&is_cdb_var' = 'YES'
UNION ALL
SELECT 
    NULL AS pdb_id,
    NULL AS pdb_name,
    df.tablespace_name, 
    df.file_name, 
    df.bytes/1024/1024 AS Size_Mo, 
    df.maxbytes/1024/1024 AS Maxsize_Mo, 
    df.autoextensible
FROM 
    dba_data_files df
WHERE '&is_cdb_var' = 'NO';
