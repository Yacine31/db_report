prompt <h2>Last Successful Backup per Type</h2>
-- Age du dernier backup reussi par type (DB FULL, DB INCR, ARCHIVELOG, ...)

select /* db-html-report */
    input_type                                     "Type",
    to_char(max(end_time), 'YYYY/MM/DD HH24:MI')   "Last Successful Backup",
    round(sysdate - max(end_time), 1)              "Age (days)",
    count(*)                                       "Successful Jobs in History"
from v$rman_backup_job_details
where status in ('COMPLETED', 'COMPLETED WITH WARNINGS')
group by input_type
order by input_type;

prompt <h2>Datafiles Without Backup in the Last 7 Days</h2>
-- Backup sets (V$BACKUP_DATAFILE) et image copies (V$DATAFILE_COPY) confondus.
-- Aucune ligne = tous les datafiles ont un backup de moins de 7 jours.

select /* db-html-report */
    d.con_id,
    d.file#                                               "File ID",
    ts.name                                               "Tablespace",
    d.name                                                "Datafile",
    d.status                                              "File Status",
    d.enabled                                             "Enabled",
    nvl(to_char(b.last_backup, 'YYYY/MM/DD HH24:MI'), 'NEVER') "Last Backup",
    round(sysdate - b.last_backup, 1)                     "Age (days)"
from v$datafile d
join v$tablespace ts
  on ts.ts# = d.ts# and ts.con_id = d.con_id
left join (
        select file#, max(completion_time) last_backup
        from (
            select file#, completion_time from v$backup_datafile where file# > 0
            union all
            select file#, completion_time from v$datafile_copy where status = 'A'
        )
        group by file#
     ) b
  on b.file# = d.file#
where b.last_backup is null
   or b.last_backup < sysdate - 7
order by b.last_backup nulls first, d.file#;

prompt <h2>Backup and Recovery Settings</h2>

select /* db-html-report */ 'LOG_MODE' as property, log_mode as value from v$database
union all
select 'FLASHBACK_ON', flashback_on from v$database
union all
select 'FORCE_LOGGING', force_logging from v$database
union all
select 'BLOCK_CHANGE_TRACKING', status from v$block_change_tracking
union all
select 'CONTROLFILE AUTOBACKUP (RMAN)',
       nvl((select max(value) from v$rman_configuration where name = 'CONTROLFILE AUTOBACKUP'), 'not configured (RMAN default)')
from dual
union all
select 'RETENTION POLICY (RMAN)',
       nvl((select max(value) from v$rman_configuration where name = 'RETENTION POLICY'), 'not configured (RMAN default)')
from dual;
