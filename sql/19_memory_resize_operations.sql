prompt <h2>Memory Resize Operations</h2>
SELECT *
  FROM gv$memory_resize_ops
  where rownum <=50
 ORDER BY
       inst_id,
       start_time DESC,
       component;
exit 
