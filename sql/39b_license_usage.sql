prompt <h2>Edition and Management Packs Setting</h2>

select /* db-html-report */ 'EDITION (V$VERSION)' as property, banner as value
from v$version
where banner like 'Oracle Database%'
union all
select 'control_management_pack_access', display_value
from v$parameter
where name = 'control_management_pack_access';

prompt <h2>Features Linked to an Extra-Cost Option or Pack (indicative)</h2>
-- Liste INDICATIVE construite a partir de DBA_FEATURE_USAGE_STATISTICS : elle ne remplace pas
-- le script officiel Oracle (MOS 1317265.1) ni une revue de licences. Les regles varient selon
-- la version et l'edition (ex. RAC inclus en SE2 jusqu'en 19c, 3 PDB incluses en 19c).
-- Aucune ligne = aucune des fonctionnalites suivies n'a ete detectee.
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

COL "Currently Used" FORMAT A14

with packs as (
    select 'Diagnostics Pack' pack, 'ADDM' pattern from dual union all
    select 'Diagnostics Pack', 'AWR Report' from dual union all
    select 'Diagnostics Pack', 'AWR Baseline%' from dual union all
    select 'Diagnostics Pack', 'Baseline Adaptive Thresholds' from dual union all
    select 'Diagnostics Pack', 'Baseline Static Computations' from dual union all
    select 'Diagnostics Pack', 'EM Performance Page' from dual union all
    select 'Tuning Pack', 'SQL Tuning Advisor' from dual union all
    select 'Tuning Pack', 'SQL Access Advisor' from dual union all
    select 'Tuning Pack', 'SQL Profile' from dual union all
    select 'Tuning Pack', 'Real-Time SQL Monitoring' from dual union all
    select 'Tuning Pack', 'SQL Monitoring and Tuning pages' from dual union all
    select 'Tuning Pack', 'SQL Tuning Set (user)' from dual union all
    select 'Partitioning', 'Partitioning (user)' from dual union all
    select 'Active Data Guard', 'Active Data Guard%' from dual union all
    select 'Real Application Clusters', 'Real Application Clusters (RAC)' from dual union all
    select 'Database In-Memory', 'In-Memory%' from dual union all
    select 'Advanced Compression', 'Backup HIGH Compression' from dual union all
    select 'Advanced Compression', 'Backup LOW Compression' from dual union all
    select 'Advanced Compression', 'Backup MEDIUM Compression' from dual union all
    select 'Advanced Compression', 'Backup ZLIB Compression' from dual union all
    select 'Advanced Compression', 'SecureFile Compression (user)' from dual union all
    select 'Advanced Compression', 'SecureFile Deduplication (user)' from dual union all
    select 'Advanced Compression', 'Advanced Index Compression' from dual union all
    select 'Advanced Compression', 'Hybrid Columnar Compression%' from dual union all
    select 'Advanced Compression', 'Heat Map' from dual union all
    select 'Advanced Compression', 'Information Lifecycle Management' from dual union all
    select 'Advanced Security', 'Transparent Data Encryption' from dual union all
    select 'Advanced Security', 'Encrypted Tablespaces' from dual union all
    select 'Advanced Security', 'Backup Encryption' from dual union all
    select 'Advanced Security', 'SecureFile Encryption (user)' from dual union all
    select 'Advanced Security', 'Data Redaction' from dual union all
    select 'Real Application Testing', 'Database Replay: Workload Capture' from dual union all
    select 'Real Application Testing', 'Database Replay: Workload Replay' from dual union all
    select 'Real Application Testing', 'SQL Performance Analyzer' from dual union all
    select 'Database Vault', 'Oracle Database Vault' from dual union all
    select 'Label Security', 'Label Security' from dual union all
    select 'OLAP', 'OLAP - %' from dual union all
    select 'Multitenant', 'Oracle Multitenant' from dual
)
select /* db-html-report */
    p.pack                      "Option / Pack",
    f.name                      "Feature",
    max(f.currently_used)       "Currently Used",
    max(f.detected_usages)      "Detected Usages",
    max(f.last_usage_date)      "Last Usage",
    max(f.aux_count)            "Aux Count"
from dba_feature_usage_statistics f
join packs p on f.name like p.pattern
where f.detected_usages > 0
  and f.dbid = (select dbid from v$database)
group by p.pack, f.name
order by p.pack, f.name;
