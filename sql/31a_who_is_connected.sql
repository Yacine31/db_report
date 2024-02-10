-- Qui est connecté à la base :
prompt <h2>Sessions Aggregate per User and Type</h2>

WITH X AS (
       SELECT
              COUNT(*),
 --con_id,
              USERNAME,
              INST_ID,
              TYPE,
              SERVER,
              STATUS,
              STATE
       FROM
              GV$SESSION
       GROUP BY
 --con_id,
              USERNAME,
              INST_ID,
              TYPE,
              SERVER,
              STATUS,
              STATE
)
SELECT
       X.*
 --,c.name con_name
FROM
       X
 --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
ORDER BY
       1 DESC,
 --x.con_id,
       X.USERNAME,
       X.INST_ID,
       X.TYPE,
       X.SERVER,
       X.STATUS,
       X.STATE;