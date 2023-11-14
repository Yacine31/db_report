prompt <h2>Les 50 dernières opérations de Resize de la mémoire :</h2>
SELECT *
  FROM gv$memory_resize_ops
  where rownum <=50
 ORDER BY
       inst_id,
       start_time DESC,
       component;
exit 
