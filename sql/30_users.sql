prompt <h2>Database Users </h2>
set pages 999
ALTER SESSION SET NLS_DATE_FORMAT ='YYYY/MM/DD HH24:MI';
-- SELECT /*+  NO_MERGE  */ 
--        x.username,
--        x.user_id,
--        x.account_status,
--        x.lock_date,
--        x.expiry_date,
--        x.default_tablespace,
--        x.temporary_tablespace,
--        x.created,
--        x.profile, x.password_versions, x.password_change_date
--        --,c.name con_name
--   FROM dba_users x
--        --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
--  ORDER BY x.username
--           --,x.con_id;

WITH version_query AS (
    SELECT SUBSTR(banner, INSTR(banner, '.') - 2, 2) AS oracle_version
    FROM v$version
    WHERE banner LIKE 'Oracle%'
)
SELECT
    CASE
        WHEN oracle_version = '19' THEN
            -- Requête pour la version 19
               SELECT x.username,
                      x.password_versions, 
                      x.password_change_date
                 FROM dba_users x ORDER BY x.username;
        ELSE
            -- Requête par défaut pour d'autres versions
               SELECT x.username,
                      x.password_versions
                 FROM dba_users x ORDER BY x.username;
    END 
    -- AS result
FROM version_query;

exit