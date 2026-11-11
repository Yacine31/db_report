prompt <h2>User Objects</h2>
-- Schemas applicatifs uniquement : la jointure sur CDB_USERS.ORACLE_MAINTAINED = 'N'
-- ecarte les schemas Oracle (et PUBLIC, qui n'est pas un utilisateur).

select /* db-html-report */
  *
FROM
  (
    SELECT
      C.NAME      AS DB_PDB_NAME,
      O.OWNER,
      O.OBJECT_TYPE,
      COUNT(*)    AS OBJECT_COUNT
    FROM
      CDB_OBJECTS O
      JOIN CDB_USERS U
        ON U.CON_ID = O.CON_ID AND U.USERNAME = O.OWNER AND U.ORACLE_MAINTAINED = 'N'
      LEFT JOIN V$CONTAINERS C ON C.CON_ID = O.CON_ID
    GROUP BY
      C.NAME,
      O.OWNER,
      O.OBJECT_TYPE
  ) PIVOT ( MAX(OBJECT_COUNT) FOR OBJECT_TYPE IN ( 
  'TABLE' AS TABLES,
  'VIEW' AS VIEWS,
  'INDEX' AS INDEXS,
  'FUNCTION' AS FUNCTIONS,
  'LOB' AS LOBS,
  'PACKAGE' AS PACKAGES,
  'PROCEDURE' AS PROCEDURES,
  'TRIGGER' AS TRIGGERS,
  'SYNONYM' AS SYNONYMS ) )
ORDER BY
  DB_PDB_NAME,
  OWNER;
