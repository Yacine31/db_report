prompt <h2>Table Statistics Summary</h2>

ALTER SESSION SET NLS_DATE_FORMAT='YYYY/MM/DD HH24:MI:SS';

WITH X AS (
  select /* db-html-report */ /*+  NO_MERGE  */
    --con_id,
    OWNER,
    OBJECT_TYPE,
    COUNT(*)                                                    TYPE_COUNT,
    SUM(DECODE(LAST_ANALYZED, NULL, 1, 0))                      NOT_ANALYZED,
    SUM(DECODE(STATTYPE_LOCKED, NULL, 0, 1))                    STATS_LOCKED,
    SUM(DECODE(STALE_STATS, 'YES', 1, 0))                       STALE_STATS,
    SUM(NUM_ROWS)                                               SUM_NUM_ROWS,
    MAX(NUM_ROWS)                                               MAX_NUM_ROWS,
    SUM(BLOCKS)                                                 SUM_BLOCKS,
    MAX(BLOCKS)                                                 MAX_BLOCKS,
    MIN(LAST_ANALYZED)                                          MIN_LAST_ANALYZED,
    MAX(LAST_ANALYZED)                                          MAX_LAST_ANALYZED,
    MEDIAN(LAST_ANALYZED)                                       MEDIAN_LAST_ANALYZED,
    PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY LAST_ANALYZED) LAST_ANALYZED_75_PERCENTILE,
    PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY LAST_ANALYZED) LAST_ANALYZED_90_PERCENTILE,
    PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY LAST_ANALYZED) LAST_ANALYZED_95_PERCENTILE,
    PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY LAST_ANALYZED) LAST_ANALYZED_99_PERCENTILE
  FROM
    DBA_TAB_STATISTICS  S
  WHERE
    TABLE_NAME NOT LIKE 'BIN$%' -- bug 9930151 reported by brad peek
    AND NOT EXISTS (
      SELECT /*+  NO_MERGE  */
        NULL
      FROM
        DBA_EXTERNAL_TABLES E
      WHERE
        E.OWNER = S.OWNER
        --AND e.con_id = s.con_id
        AND E.TABLE_NAME = S.TABLE_NAME
    )
  GROUP BY
    --con_id,
    OWNER,
    OBJECT_TYPE
)
SELECT
  X.*
  --,c.name con_name
FROM
  X
  --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
ORDER BY
  --x.con_id,
  OWNER,
  OBJECT_TYPE;