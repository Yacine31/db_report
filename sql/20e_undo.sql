prompt <h2>Détail du tablespace UNDO : </h2>

col tablespace_name head "Tablespace Name"
col file_id head "File ID"
col size_mb format 999999999 head "Size MB"
col autoextensible head "AutoExt"
col free_mb format 999999999 head "Free MB"
col used_mb format 999999999 head "Used MB"
col pct_used format 99.00 head "% Used"

select /* db-html-report */
    a.tablespace_name,
    a.file_id,
    a.bytes / 1024 / 1024 AS size_mb,
    a.autoextensible,
    b.bytes_free / 1024 / 1024 AS free_mb,
    (a.bytes - b.bytes_free) / 1024 / 1024 AS used_mb,
    ROUND(((a.bytes - b.bytes_free) / a.bytes) * 100, 2) AS pct_used
FROM
    dba_data_files a
JOIN
    (SELECT file_id, SUM(bytes) AS bytes_free
     FROM dba_free_space
     GROUP BY file_id) b
ON a.file_id = b.file_id
WHERE a.tablespace_name like 'UNDO%';
