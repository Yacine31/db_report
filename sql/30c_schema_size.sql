-- db-report: requires-open
prompt <h2>Schema Size (MB)</h2>

COL "Oracle Maintained" FORMAT A17

select /* db-html-report */
    C.NAME                             "DB/PDB Name",
    DS.OWNER                           "Owner",
    ROUND(SUM(DS.BYTES) / 1024 / 1024) "Schema Size MB",
    DU.DEFAULT_TABLESPACE              "Default Tablespace",
    DU.ORACLE_MAINTAINED               "Oracle Maintained"
FROM
    CDB_SEGMENTS DS
    JOIN CDB_USERS DU
      ON DU.CON_ID = DS.CON_ID AND DU.USERNAME = DS.OWNER
    LEFT JOIN V$CONTAINERS C ON C.CON_ID = DS.CON_ID
GROUP BY
    C.NAME,
    DS.OWNER,
    DU.DEFAULT_TABLESPACE,
    DU.ORACLE_MAINTAINED
ORDER BY
    C.NAME,
    DS.OWNER;
