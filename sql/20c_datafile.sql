prompt <h2>Détail des datafiles : </h2>


ECLARE
    v_is_cdb VARCHAR2(3);
BEGIN
    -- Vérifier si la base de données est une CDB
    SELECT cdb INTO v_is_cdb FROM v$database;

    IF v_is_cdb = 'YES' THEN
        -- Si la base de données est une CDB, exécuter la requête avec pdb_id et pdb_name
        DBMS_OUTPUT.PUT_LINE('PDB ID: ' || rec.pdb_id || 
                             ', PDB Name: ' || rec.pdb_name || 
                             ', Tablespace Name: ' || rec.tablespace_name || 
                             ', File Name: ' || rec.file_name || 
                             ', Size (MB): ' || rec.Size_Mo || 
                             ', Max Size (MB): ' || rec.Maxsize_Mo || 
                             ', Autoextensible: ' || rec.autoextensible);
        FOR rec IN (
            SELECT 
                p.pdb_id AS pdb_id,
                p.pdb_name AS pdb_name,
                df.tablespace_name, 
                df.file_name, 
                df.bytes/1024/1024 AS Size_Mo, 
                df.maxbytes/1024/1024 AS Maxsize_Mo, 
                df.autoextensible
            FROM 
                cdb_data_files df 
            JOIN 
                cdb_pdbs p 
            ON 
                df.con_id = p.pdb_id
            ORDER BY p.pdb_name
        )
        LOOP
            DBMS_OUTPUT.PUT_LINE('PDB ID: ' || rec.pdb_id || 
                                 ', PDB Name: ' || rec.pdb_name || 
                                 ', Tablespace Name: ' || rec.tablespace_name || 
                                 ', File Name: ' || rec.file_name || 
                                 ', Size (MB): ' || rec.Size_Mo || 
                                 ', Max Size (MB): ' || rec.Maxsize_Mo || 
                                 ', Autoextensible: ' || rec.autoextensible);
        END LOOP;
    ELSE
        -- Si la base de données n'est pas une CDB, exécuter la requête sans pdb_id et pdb_name
        FOR rec IN (
            SELECT 
                df.tablespace_name, 
                df.file_name, 
                df.bytes/1024/1024 AS Size_Mo, 
                df.maxbytes/1024/1024 AS Maxsize_Mo, 
                df.autoextensible 
            FROM 
                dba_data_files df
            ORDER BY
            	df.tablespace_name, 
            	df.file_name
        )
        LOOP
            DBMS_OUTPUT.PUT_LINE('Tablespace Name: ' || rec.tablespace_name || 
                                 ', File Name: ' || rec.file_name || 
                                 ', Size (MB): ' || rec.Size_Mo || 
                                 ', Max Size (MB): ' || rec.Maxsize_Mo || 
                                 ', Autoextensible: ' || rec.autoextensible);
        END LOOP;
    END IF;
END;
/
