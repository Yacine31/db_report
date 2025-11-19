prompt <h2>Les 50 dernières opérations de Resize de la mémoire :</h2>

ALTER SESSION SET NLS_DATE_FORMAT='YYYY/MM/DD HH24:MI:SS';

select /* db-html-report */
  *
FROM
  GV$MEMORY_RESIZE_OPS
WHERE
  ROWNUM <=50
ORDER BY
  INST_ID,
  START_TIME DESC,
  COMPONENT;