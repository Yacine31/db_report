prompt <h2>Database Health Summary</h2>
-- Synthese des points d'attention de la base : une ligne par controle, avec sa valeur,
-- son seuil et un statut OK / WARNING / CRITICAL / INFO. Le detail de chaque controle se
-- trouve dans la section correspondante du rapport.
--
-- Ce script est aussi appele par summary/10_health_summary.sql (page Summary_health).
-- Il utilise des variables de substitution : ne pas mettre de "et commercial" dans ce fichier.

SET DEFINE ON
SET VERIFY OFF

-- ============================== SEUILS ==============================
-- Tablespaces : % utilise par rapport a la taille maximale (autoextend compris)
DEFINE tbs_warn_pct     = 85
DEFINE tbs_crit_pct     = 95
-- Fast Recovery Area : % non recuperable
DEFINE fra_warn_pct     = 80
DEFINE fra_crit_pct     = 90
-- Age du dernier backup reussi de la base (full ou incremental), en jours
DEFINE backup_warn_days = 2
DEFINE backup_crit_days = 7
-- Fenetre d'analyse (alert log, jobs RMAN et scheduler en echec), en jours : 30, le rapport
-- etant prevu pour une execution mensuelle
DEFINE recent_days      = 30
-- Age du dernier patch SQL applique (datapatch), en jours
DEFINE patch_warn_days  = 200
DEFINE patch_crit_days  = 400
-- Pic d'utilisation du parametre processes, en %
DEFINE proc_warn_pct    = 80
DEFINE proc_crit_pct    = 90
-- Sequences : % de la valeur maximale
DEFINE seq_warn_pct     = 80
-- =====================================================================

COL "Value" ENTMAP ON

with ts as (
    -- meme calcul que la colonne "% Used (max)" de sql/common/tablespaces.sql
    select a.con_id, a.tablespace_name,
           (a.bytes_alloc - nvl(b.bytes_free, 0)) / a.maxbytes * 100 pct
    from (
            select con_id, tablespace_name, sum(bytes) bytes_alloc,
                   sum(decode(autoextensible, 'YES', maxbytes, 'NO', bytes)) maxbytes
            from cdb_data_files
            group by con_id, tablespace_name
         ) a
    left join (
            select con_id, tablespace_name, sum(bytes) bytes_free
            from cdb_free_space
            group by con_id, tablespace_name
         ) b
      on b.con_id = a.con_id and b.tablespace_name = a.tablespace_name
),
checks as (
    select 10 ord, 'Open mode / role' check_name,
           open_mode || ' / ' || database_role value,
           '-' threshold,
           'INFO' status
    from v$database
    union all
    select 15, 'Last SQL patch applied (datapatch)',
           nvl(max(to_char(action_time, 'YYYY/MM/DD') || ' (' || trunc(sysdate - cast(action_time as date)) || ' days ago) '
                   || substr(description, 1, 70)) keep (dense_rank last order by action_time),
               'no patch recorded in DBA_REGISTRY_SQLPATCH'),
           'warn > &patch_warn_days days / crit > &patch_crit_days days',
           case
               when max(action_time) is null then 'WARNING'
               when sysdate - cast(max(action_time) as date) > &patch_crit_days then 'CRITICAL'
               when sysdate - cast(max(action_time) as date) > &patch_warn_days then 'WARNING'
               else 'OK'
           end
    from dba_registry_sqlpatch
    where action = 'APPLY' and status = 'SUCCESS'
    union all
    select 20, 'Archive log mode',
           log_mode,
           'ARCHIVELOG expected',
           case when log_mode = 'ARCHIVELOG' then 'OK' else 'WARNING' end
    from v$database
    union all
    select 30, 'Tablespace usage (% of max size)',
           sum(case when pct >= &tbs_warn_pct then 1 else 0 end) || ' of ' || count(*) || ' above &tbs_warn_pct%, highest: '
               || max(tablespace_name) keep (dense_rank last order by pct) || ' ' || to_char(max(pct), 'FM990.0') || '%',
           'warn &tbs_warn_pct% / crit &tbs_crit_pct%',
           case
               when max(pct) >= &tbs_crit_pct then 'CRITICAL'
               when max(pct) >= &tbs_warn_pct then 'WARNING'
               else 'OK'
           end
    from ts
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
    select 110, 'Invalid registry components (CDB_REGISTRY)',
           to_char(count(*)),
           '0 expected',
           case when count(*) > 0 then 'WARNING' else 'OK' end
    from cdb_registry
    where status not in ('VALID', 'OPTION OFF', 'REMOVED')
    union all
    select 120, 'Invalid objects',
           to_char(count(*)),
           '0 expected',
           case when count(*) > 0 then 'WARNING' else 'OK' end
    from cdb_objects
    where status <> 'VALID'
    union all
    select 130, 'Unusable indexes (including partitions)',
           to_char(
               (select count(*) from cdb_indexes where status = 'UNUSABLE')
             + (select count(*) from cdb_ind_partitions where status = 'UNUSABLE')
             + (select count(*) from cdb_ind_subpartitions where status = 'UNUSABLE')),
           '0 expected',
           case
               when (select count(*) from cdb_indexes where status = 'UNUSABLE')
                  + (select count(*) from cdb_ind_partitions where status = 'UNUSABLE')
                  + (select count(*) from cdb_ind_subpartitions where status = 'UNUSABLE') > 0 then 'WARNING'
               else 'OK'
           end
    from dual
    union all
    select 140, 'Failed scheduler job runs (last &recent_days days)',
           to_char(count(*)),
           '0 expected',
           case when count(*) > 0 then 'WARNING' else 'OK' end
    from cdb_scheduler_job_run_details
    where status = 'FAILED'
      and log_date > systimestamp - &recent_days
    union all
    select 150, 'Automatic optimizer statistics collection',
           nvl(max(status), 'not found'),
           'ENABLED expected',
           case when max(status) = 'ENABLED' then 'OK' else 'WARNING' end
    -- DBA_AUTOTASK_OPERATION et non DBA_AUTOTASK_CLIENT : cette derniere peut prendre
    -- plusieurs dizaines de secondes sur une base avec un long historique de taches
    from dba_autotask_operation
    where client_name = 'auto optimizer stats collection'
    union all
    select 160, 'Accounts with a default password',
           nvl(sum(case when u.account_status = 'OPEN' then 1 else 0 end), 0) || ' open, ' || count(*) || ' in total',
           '0 open expected',
           case when nvl(sum(case when u.account_status = 'OPEN' then 1 else 0 end), 0) > 0 then 'CRITICAL' else 'OK' end
    from cdb_users_with_defpwd d
    join cdb_users u on u.con_id = d.con_id and u.username = d.username
    union all
    select 170, 'Guaranteed restore points',
           to_char(count(*)),
           '0 expected outside a planned operation',
           case when count(*) > 0 then 'WARNING' else 'OK' end
    from v$restore_point
    where guarantee_flashback_database = 'YES'
    union all
    select 180, 'Application sequences above &seq_warn_pct% of their maximum',
           to_char(count(*)),
           '0 expected',
           case when count(*) > 0 then 'WARNING' else 'OK' end
    from cdb_sequences s
    join cdb_users u on u.con_id = s.con_id and u.username = s.sequence_owner and u.oracle_maintained = 'N'
    where s.cycle_flag = 'N'
      and s.increment_by > 0
      and s.max_value > 0
      and s.last_number / s.max_value * 100 > &seq_warn_pct
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
    union all
    select 195, 'PDB plug-in violations (unresolved errors)',
           to_char(count(*)),
           '0 expected',
           case when count(*) > 0 then 'WARNING' else 'OK' end
    from pdb_plug_in_violations
    where status <> 'RESOLVED'
      and type like 'ERROR%'
)
select /* db-html-report */
    check_name  "Check",
    value       "Value",
    threshold   "Threshold",
    status      "Status"
from checks
order by ord;

SET DEFINE OFF
