-- db-report: requires-open
-- Seconde partie de la synthese de sante (voir sql/00a_health_summary.sql) : controles qui
-- lisent le dictionnaire (DBA_*, CDB_*), donc qui demandent une base ouverte. Pas de titre :
-- le tableau s'affiche sous "Database Health Summary".
-- Utilise des variables de substitution : ne pas mettre de "et commercial" dans ce fichier.

SET DEFINE ON
SET VERIFY OFF
@sql/common/health_thresholds.sql

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
    -- le premier controle donne les noms de colonnes (ord, check_name, value, threshold, status)
    select 15 ord, 'Last SQL patch applied (datapatch)' check_name,
           nvl(max(to_char(action_time, 'YYYY/MM/DD') || ' (' || trunc(sysdate - cast(action_time as date)) || ' days ago) '
                   || substr(description, 1, 70)) keep (dense_rank last order by action_time),
               'no patch recorded in DBA_REGISTRY_SQLPATCH') value,
           'warn > &patch_warn_days days / crit > &patch_crit_days days' threshold,
           case
               when max(action_time) is null then 'WARNING'
               when sysdate - cast(max(action_time) as date) > &patch_crit_days then 'CRITICAL'
               when sysdate - cast(max(action_time) as date) > &patch_warn_days then 'WARNING'
               else 'OK'
           end status
    from dba_registry_sqlpatch
    where action = 'APPLY' and status = 'SUCCESS'
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
