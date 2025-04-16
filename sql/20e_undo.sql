prompt <h3>Détail du tablespace UNDO : </h3>

SELECT
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
WHERE a.tablespace_name like 'UNDO%';  -- ou le nom réel de ton UNDO

prompt <h3>Durée de rétention UNDO : </h3>
SELECT
    retention,
    tuned_undoretention,
    undoblks,
    expiredblks,
    unexpiredblks,
    tuned_undoretention
FROM
    v$undostat
ORDER BY
    begin_time DESC FETCH FIRST 10 ROWS ONLY;

prompt <h3>Occupation de l’espace dans le UNDO par session : </h3>
SELECT
    s.sid,
    s.serial#,
    u.name AS username,
    t.used_urec,
    t.used_ublk
FROM
    v$transaction t
JOIN v$session s ON t.ses_addr = s.saddr
JOIN all_users u ON s.user# = u.user_id;
