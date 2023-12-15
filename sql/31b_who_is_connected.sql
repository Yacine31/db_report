prompt <h2>Sessions Aggregate per Module and Action</h2>
WITH x AS (
SELECT COUNT(*),
	   --con_id,
       module,
       action,
       inst_id,
       type,
       server,
       status,
       state
  FROM gv$session
 GROUP BY
	   --con_id,
       module,
       action,
       inst_id,
       type,
       server,
       status,
       state
)
SELECT x.*
      --,c.name con_name
FROM   x
       --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
 ORDER BY
       1 DESC,
	   --x.con_id,
	   x.module, x.action, x.inst_id, x.type, x.server, x.status, x.state;
