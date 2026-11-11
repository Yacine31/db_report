prompt <h2>Last Memory Resize Ops</h2>

ALTER SESSION SET NLS_DATE_FORMAT='YYYY/MM/DD HH24:MI:SS';

select /* db-html-report */
  *
FROM
  -- tri AVANT le filtre ROWNUM pour garder les 50 operations les plus recentes
  ( SELECT * FROM GV$MEMORY_RESIZE_OPS ORDER BY START_TIME DESC )
WHERE
  ROWNUM <=50
ORDER BY
  INST_ID,
  START_TIME DESC,
  COMPONENT;