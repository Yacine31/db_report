prompt <h2>Failed scheduled jobs </h2>

select /* db-html-report */
    OWNER,
    JOB_NAME,
    JOB_TYPE,
    STATE,
    TRUNC(START_DATE)    SDATE,
    TRUNC(NEXT_RUN_DATE) NXTRUN,
    FAILURE_COUNT
FROM
    DBA_SCHEDULER_JOBS
WHERE
    FAILURE_COUNT <> 0;