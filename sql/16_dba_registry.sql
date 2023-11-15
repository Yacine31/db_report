prompt <h2>Fonctionnalités installées dans la base de données (DBA_REGISTRY) :</h2>
SELECT *  
--        COMP_ID,
--        COMP_NAME,
--        VERSION,
--        VERSION_FULL,
--        STATUS,
--        MODIFIED,
--        SCHEMA,
--        PROCEDURE
  FROM dba_registry x
ORDER BY
	   comp_id;



