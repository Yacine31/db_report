prompt <h2>DBA Users </h2>
set pages 999
ALTER SESSION SET NLS_DATE_FORMAT ='YYYY/MM/DD HH24:MI';
SELECT 
       x.username,
       x.user_id,
       x.account_status,
       x.lock_date,
       x.expiry_date,
       x.default_tablespace,
       x.temporary_tablespace,
       x.created,
       x.profile, 
       x.password_versions
  FROM dba_users x
 ORDER BY x.username
;

prompt <h2>DBA_Profiles </h2>
select * from DBA_Profiles order by profile, resource_name;

exit