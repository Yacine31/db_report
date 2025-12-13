prompt <h2>Failed scheduled jobs </h2>

select /* db-html-report */
    OWNER,
    JOB_NAME,
    JOB_TYPE,
    STATE,
    START_DATE,
    NEXT_RUN_DATE,
    FAILURE_COUNT
FROM
    DBA_SCHEDULER_JOBS
WHERE
    FAILURE_COUNT <> 0;