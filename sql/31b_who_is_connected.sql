prompt <h2>Sessions by Module/Action</h2>

WITH X AS (
      select /* db-html-report */
            COUNT(*),
 --con_id,
            MODULE,
            ACTION,
            INST_ID,
            TYPE,
            SERVER,
            STATUS,
            STATE
      FROM
            GV$SESSION
      GROUP BY
 --con_id,
            MODULE,
            ACTION,
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
      X.MODULE,
      X.ACTION,
      X.INST_ID,
      X.TYPE,
      X.SERVER,
      X.STATUS,
      X.STATE;