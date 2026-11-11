prompt <h2>Invalid Objects</h2>

select /* db-html-report */
    C.NAME      "DB/PDB Name",
    O.OWNER,
    COUNT(*)    "Invalid Objects"
FROM
    CDB_OBJECTS O
    LEFT JOIN V$CONTAINERS C ON C.CON_ID = O.CON_ID
WHERE
    O.STATUS <> 'VALID'
GROUP BY
    C.NAME,
    O.OWNER
ORDER BY
    C.NAME,
    O.OWNER;
