prompt <h2>Database Health Summary</h2>
-- Synthese des points d'attention de la base : une ligne par controle, avec sa valeur,
-- son seuil et un statut OK / WARNING / CRITICAL / INFO. Le detail de chaque controle se
-- trouve dans la section correspondante du rapport.
--
-- La synthese est en deux parties, affichees l'une sous l'autre sous ce titre :
--   - ce script : controles qui ne lisent que des vues V$/X$, possibles sur une base montee (standby) ;
--   - sql/00b_health_summary_open.sql : controles qui demandent une base ouverte.
-- Les seuils sont dans sql/common/health_thresholds.sql.
-- Ces scripts sont aussi appeles par summary/10_health_summary.sql et summary/11_health_open.sql (page Summary_health).
-- Ils utilisent des variables de substitution : ne pas y mettre de "et commercial".

SET DEFINE ON
SET VERIFY OFF
@sql/common/health_thresholds.sql

COL "Value" ENTMAP ON

-- Sous-requete et non clause WITH : sur une base montee, Oracle refuse une requete
-- avec WITH (ORA-01219), meme si elle ne lit que des vues V$.
select /* db-html-report */
    check_name  "Check",
    value       "Value",
    threshold   "Threshold",
    status      "Status"
from (
    select 10 ord, 'Open mode / role' check_name,
           open_mode || ' / ' || database_role value,
           '-' threshold,
           'INFO' status
    from v$database
    union all
    select 20, 'Archive log mode',
           log_mode,
           'ARCHIVELOG expected',
           case when log_mode = 'ARCHIVELOG' then 'OK' else 'WARNING' end
    from v$database
    union all
    select 40, 'Fast Recovery Area usage (non-reclaimable)',
           case
               when nvl(max(space_limit), 0) = 0 then 'not configured'
               else to_char(max((space_used - space_reclaimable) / space_limit * 100), 'FM990.0') || '%'
           end,
           'warn &fra_warn_pct% / crit &fra_crit_pct%',
           case
               when nvl(max(space_limit), 0) = 0 then 'INFO'
               when max((space_used - space_reclaimable) / space_limit * 100) >= &fra_crit_pct then 'CRITICAL'
               when max((space_used - space_reclaimable) / space_limit * 100) >= &fra_warn_pct then 'WARNING'
               else 'OK'
           end
    from v$recovery_file_dest
    union all
    select 50, 'Last successful database backup (full or incremental)',
           case
               when max(end_time) is null then 'none in RMAN history'
               else to_char(max(end_time), 'YYYY/MM/DD HH24:MI') || ' (' || to_char(sysdate - max(end_time), 'FM99990.0') || ' days ago)'
           end,
           'warn > &backup_warn_days days / crit > &backup_crit_days days',
           case
               when max(end_time) is null then 'CRITICAL'
               when sysdate - max(end_time) > &backup_crit_days then 'CRITICAL'
               when sysdate - max(end_time) > &backup_warn_days then 'WARNING'
               else 'OK'
           end
    from v$rman_backup_job_details
    where status in ('COMPLETED', 'COMPLETED WITH WARNINGS')
      and input_type in ('DB FULL', 'DB INCR')
    union all
    select 55, 'Failed RMAN jobs (last &recent_days days)',
           to_char(count(*)),
           '0 expected',
           case when count(*) > 0 then 'WARNING' else 'OK' end
    from v$rman_backup_job_details
    where status in ('FAILED', 'COMPLETED WITH ERRORS')
      and start_time > sysdate - &recent_days
    union all
    select 60, 'Datafiles without backup in the last 7 days',
           count(case when last_backup is null or last_backup < sysdate - 7 then 1 end) || ' of ' || count(*),
           '0 expected',
           case when count(case when last_backup is null or last_backup < sysdate - 7 then 1 end) > 0 then 'WARNING' else 'OK' end
    from (
            -- backup sets et image copies confondus, comme dans sql/27b_backup_recency.sql
            select d.file#,
                   greatest(
                       nvl((select max(completion_time) from v$backup_datafile b where b.file# = d.file#), date '1900-01-01'),
                       nvl((select max(completion_time) from v$datafile_copy c where c.file# = d.file# and c.status = 'A'), date '1900-01-01')
                   ) last_backup
            from v$datafile d
         )
    union all
    select 70, 'Alert log ORA- errors (last &recent_days days)',
           count(*) || ' errors, of which '
               || nvl(sum(case when regexp_like(message_text, 'ORA-0*(600|7445|1578|4031)([^0-9]|$)') then 1 else 0 end), 0)
               || ' ORA-600/7445/1578/4031',
           '0 expected',
           case
               when nvl(sum(case when regexp_like(message_text, 'ORA-0*(600|7445|1578|4031)([^0-9]|$)') then 1 else 0 end), 0) > 0 then 'CRITICAL'
               when count(*) > 0 then 'WARNING'
               else 'OK'
           end
    from x$dbgalertext
    where originating_timestamp > systimestamp - &recent_days
      and message_text like '%ORA-%'
    union all
    select 75, 'ORA-01555 snapshot too old (V$UNDOSTAT, last 24 hours)',
           to_char(nvl(sum(ssolderrcnt), 0)),
           '0 expected',
           case when nvl(sum(ssolderrcnt), 0) > 0 then 'WARNING' else 'OK' end
    from v$undostat
    where begin_time > sysdate - 1
    union all
    select 80, 'Corrupted blocks (V$DATABASE_BLOCK_CORRUPTION)',
           to_char(count(*)),
           '0 expected',
           case when count(*) > 0 then 'CRITICAL' else 'OK' end
    from v$database_block_corruption
    union all
    select 90, 'Redo log groups / members',
           count(*) || ' groups, ' || min(members) || ' member(s) minimum',
           '3 groups and 2 members minimum',
           case when count(*) < 3 or min(members) < 2 then 'WARNING' else 'OK' end
    from v$log
    union all
    select 100, 'Peak usage of the processes parameter',
           trim(max_utilization) || ' of ' || trim(limit_value) || ' ('
               || to_char(to_number(trim(max_utilization)) / to_number(trim(limit_value)) * 100, 'FM990') || '%)',
           'warn &proc_warn_pct% / crit &proc_crit_pct%',
           case
               when to_number(trim(max_utilization)) / to_number(trim(limit_value)) * 100 >= &proc_crit_pct then 'CRITICAL'
               when to_number(trim(max_utilization)) / to_number(trim(limit_value)) * 100 >= &proc_warn_pct then 'WARNING'
               else 'OK'
           end
    from v$resource_limit
    where resource_name = 'processes'
    union all
    select 170, 'Guaranteed restore points',
           to_char(count(*)),
           '0 expected outside a planned operation',
           case when count(*) > 0 then 'WARNING' else 'OK' end
    from v$restore_point
    where guarantee_flashback_database = 'YES'
    union all
    select 190, 'PDBs not open in read write',
           case when max(d.cdb) = 'NO' then 'not a CDB'
                else count(case when p.open_mode <> 'READ WRITE' then 1 end) || ' of ' || count(p.name) end,
           '0 expected',
           case when count(case when p.open_mode <> 'READ WRITE' then 1 end) > 0 then 'WARNING'
                when max(d.cdb) = 'NO' then 'INFO'
                else 'OK' end
    from (select cdb from v$database) d
    left join v$pdbs p on p.name <> 'PDB$SEED'
) checks
order by ord;

SET DEFINE OFF
