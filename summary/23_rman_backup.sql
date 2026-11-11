prompt <h3>Last RMAN Backup</h3>

ALTER SESSION SET NLS_DATE_FORMAT='DD/MM/YYYY HH24:MI:SS';

-- tri AVANT le filtre ROWNUM pour garder les 50 derniers jobs
select /* db-html-report */
    *
FROM (
SELECT
    B.SESSION_KEY                                                                      "Session Key",
    B.INPUT_TYPE                                                                       "Type",
    TO_CHAR(B.START_TIME, 'DD-MM-YYYY HH24:MI')                                        "Start Time",
    TO_CHAR(B.END_TIME, 'DD-MM-YYYY HH24:MI')                                          "End Time",
    TO_CHAR(TRUNC(SYSDATE) + NUMTODSINTERVAL(ELAPSED_SECONDS, 'second'), 'hh24:mi:ss') "Duration",
    B.OUTPUT_DEVICE_TYPE                                                               "Device Type",
    B.INPUT_BYTES_DISPLAY                                                              "Input Bytes",
    B.OUTPUT_BYTES_DISPLAY                                                             "Output Bytes",
    CASE
        WHEN B.STATUS = 'FAILED' THEN
            '<span class="highlight">'
            || B.STATUS
            || '</span>'
        ELSE
            B.STATUS
    END                                                                                "Status"
FROM
    V$RMAN_BACKUP_JOB_DETAILS B
WHERE
    B.START_TIME > ( SYSDATE - 30 )
ORDER BY
    B.SESSION_KEY DESC
)
WHERE
    ROWNUM <= 50;
