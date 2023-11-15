prompt <h2>Database/Instance Status</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';
select 
 inst_id,
 instance_name,
 host_name, 
to_char(startup_time ,'DD/MM/YYYY HH24:MI:SS') startup_time, 
 status,
-- VERSION_FULL,
-- EDITION,
 ARCHIVER,
 INSTANCE_ROLE,
 database_status,
logins 
FROM  gv$instance;

SELECT 
 inst_id,
 name,
 to_char(CREATED ,'DD/MM/YYYY HH24:MI:SS') CREATED ,
 open_mode,
 DATABASE_ROLE,
 log_mode,
 FORCE_LOGGING,
 CURRENT_SCN FROM gv$database;

select * from v$version;


