prompt <h2>Failed Scheduled Jobs</h2>

select /* db-html-report */
    C.NAME      "DB/PDB Name",
    J.OWNER,
    J.JOB_NAME,
    J.JOB_TYPE,
    J.STATE,
    J.START_DATE,
    J.NEXT_RUN_DATE,
    J.FAILURE_COUNT
FROM
    CDB_SCHEDULER_JOBS J
    LEFT JOIN V$CONTAINERS C ON C.CON_ID = J.CON_ID
WHERE
    J.FAILURE_COUNT <> 0
ORDER BY
    C.NAME,
    J.OWNER,
    J.JOB_NAME;
