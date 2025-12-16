prompt <h2>CDB/PDB Tempfile</h2>

SELECT /*+  NO_MERGE  */ /* db-html-report */
       x.*
	   ,c.name con_name
  FROM v$tempfile x
       LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
 ORDER BY
       file#;