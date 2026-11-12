-- db-report: requires-open
prompt <h2>Undo Tablespace Details</h2>
-- Un datafile par ligne, pour chaque conteneur : avec l'undo local (defaut en 19c), chaque PDB
-- a son propre tablespace d'undo, que DBA_* (vue depuis CDB$ROOT) ne montre pas.
-- L'espace "libre" ne compte que les extents non alloues : les extents expires, reutilisables,
-- sont comptes comme utilises.

col con_id head "CON ID"
col pdb_name head "DB/PDB Name"
col tablespace_name head "Tablespace Name"
col file_id head "File ID"
col size_mb format 999999999 head "Size MB"
col autoextensible format a7 head "AutoExt"
col free_mb format 999999999 head "Free MB"
col used_mb format 999999999 head "Used MB"
col pct_used format 999.00 head "% Used"

select /* db-html-report */
    c.con_id,
    c.name AS pdb_name,
    a.tablespace_name,
    a.file_id,
    a.bytes / 1024 / 1024 AS size_mb,
    a.autoextensible,
    NVL(b.bytes_free, 0) / 1024 / 1024 AS free_mb,
    (a.bytes - NVL(b.bytes_free, 0)) / 1024 / 1024 AS used_mb,
    ROUND(((a.bytes - NVL(b.bytes_free, 0)) / NULLIF(a.bytes, 0)) * 100, 2) AS pct_used
FROM
    cdb_data_files a
JOIN
    cdb_tablespaces t
ON t.con_id = a.con_id AND t.tablespace_name = a.tablespace_name
JOIN
    v$containers c
ON c.con_id = a.con_id
-- LEFT JOIN : un fichier sans espace libre doit rester visible
LEFT JOIN
    (SELECT con_id, file_id, SUM(bytes) AS bytes_free
     FROM cdb_free_space
     GROUP BY con_id, file_id) b
ON b.con_id = a.con_id AND b.file_id = a.file_id
WHERE t.contents = 'UNDO'
ORDER BY c.con_id, a.tablespace_name, a.file_id;
