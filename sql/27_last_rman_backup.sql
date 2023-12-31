prompt <h2>Les dernières sauvegardes RMAN (30 derniers jours/50 dernières lignes)</h2>
alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS' ;
-- set linesize 250 heading off;
-- set heading on pagesize 999;
-- column status format a25;
-- column input_bytes_display format a12;
-- column output_bytes_display format a12;
-- column device_type format a10;

SELECT
    b.SESSION_KEY                               "Session Key",
    b.input_type                                "Type",
    to_char(b.start_time, 'DD-MM-YYYY HH24:MI') "Start Time",
    to_char(b.end_time, 'DD-MM-YYYY HH24:MI')   "End Time",
    to_char(trunc(sysdate) + numtodsinterval(ELAPSED_SECONDS, 'second'),'hh24:mi:ss') "Duration",
    b.output_device_type                        "Device Type",
    b.input_bytes_display                       "Input Bytes",
    b.output_bytes_display                      "Output Bytes",
    CASE
        WHEN b.status = 'FAILED' THEN
            '<span class="highlight">' || b.status || '</span>'
        ELSE
            b.status
    END                                         "Status"
FROM
    v$rman_backup_job_details b
WHERE
        b.start_time > ( sysdate - 30 )
    AND ROWNUM <= 50
ORDER BY
    b.SESSION_KEY desc;
--    b.start_time DESC;

