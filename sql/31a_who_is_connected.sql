-- Qui est connecté à la base :
prompt <h2>Sessions Aggregate per User and Type</h2>
WITH x as (
SELECT COUNT(*),
	   --con_id,
       username,
       inst_id,
       type,
       server,
       status,
       state
  FROM gv$session
 GROUP BY
	   --con_id,
       username,
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
	   x.username, x.inst_id, x.type, x.server, x.status, x.state;
