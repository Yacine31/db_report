prompt <h2>Les 50 dernières opérations de Resize de la mémoire :</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';
SELECT *
  FROM gv$memory_resize_ops
  where rownum <=50
 ORDER BY
       inst_id,
       start_time DESC,
       component;
