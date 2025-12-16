prompt <h2>Temp Tablespace</h2>

-- SELECT /*+  NO_MERGE  */ /* db-html-report */
--        x.*
-- 	   ,c.name con_name
--   FROM v$tempfile x
--        LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
--  ORDER BY
--        file#;

select /* db-html-report */
c.CON_ID, 
c.NAME "DB/PDB Name",
f.TABLESPACE_NAME "Tablespace Name",
round(f.TABLESPACE_SIZE/power(10,6),0) "TBS Size MB",
round(f.ALLOCATED_SPACE/power(10,6),0) "Allocated MB",
round(f.FREE_SPACE/power(10,6),0) "Free Space MB",
round(100*f.FREE_SPACE/f.TABLESPACE_SIZE,1) "Free %"
from CDB_TEMP_FREE_SPACE f
left OUTER JOIN v$containers c ON c.con_id = f.con_id
order by f.CON_ID, f.TABLESPACE_NAME;
