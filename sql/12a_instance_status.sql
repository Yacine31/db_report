prompt <h2>Database/Instance Status</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

select /* db-html-report */ 'DATABASE_NAME' AS property, name AS value FROM gv$database
UNION ALL
SELECT 'DATABASE_ROLE' AS property, DATABASE_ROLE AS value FROM gv$database
UNION ALL
SELECT 'OPEN_MODE' AS property, open_mode AS value FROM gv$database
UNION ALL
select 'INSTANCE_NAME' as property, INSTANCE_NAME as value from v$instance
union all
select 'INSTANCE_ROLE' as property, INSTANCE_ROLE as value from v$instance
union all
select 'LOGINS' as property, LOGINS as value from v$instance
union all
SELECT 'LOG_MODE' AS property, log_mode AS value FROM gv$database
UNION ALL
SELECT 'FORCE_LOGGING' AS property, FORCE_LOGGING AS value FROM gv$database
UNION ALL
select 'VERSION' as property, VERSION as value from v$instance
union all
SELECT 'CREATED' AS property, to_char(CREATED ,'DD/MM/YYYY HH24:MI:SS') AS value FROM gv$database
UNION ALL
select 'STARTUP_TIME' as property, to_char(STARTUP_TIME,'DD/MM/YYYY HH24:MI:SS') as value from v$instance
UNION ALL
SELECT 'CURRENT_SCN' AS property, to_char(CURRENT_SCN) AS value FROM gv$database;




