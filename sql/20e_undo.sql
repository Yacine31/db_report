prompt <h2>Undo Tablespace Details</h2>

col tablespace_name head "Tablespace Name"
col file_id head "File ID"
col size_mb format 999999999 head "Size MB"
col autoextensible head "AutoExt"
col free_mb format 999999999 head "Free MB"
col used_mb format 999999999 head "Used MB"
col pct_used format 999.00 head "% Used"

select /* db-html-report */
    a.tablespace_name,
    a.file_id,
    a.bytes / 1024 / 1024 AS size_mb,
    a.autoextensible,
    NVL(b.bytes_free, 0) / 1024 / 1024 AS free_mb,
    (a.bytes - NVL(b.bytes_free, 0)) / 1024 / 1024 AS used_mb,
    ROUND(((a.bytes - NVL(b.bytes_free, 0)) / a.bytes) * 100, 2) AS pct_used
FROM
    dba_data_files a
JOIN
    dba_tablespaces t
ON t.tablespace_name = a.tablespace_name
-- LEFT JOIN : un fichier sans espace libre doit rester visible
LEFT JOIN
    (SELECT file_id, SUM(bytes) AS bytes_free
     FROM dba_free_space
     GROUP BY file_id) b
ON a.file_id = b.file_id
WHERE t.contents = 'UNDO'
ORDER BY a.tablespace_name, a.file_id;
