SET DEFINE OFF
prompt <h2>Data Guard — Database Role &amp; Protection</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

-- Largeurs explicites : sans elles, l'en-tete est coupe a la largeur de la colonne
COL dataguard_broker FORMAT A16
COL guard_status     FORMAT A12

select /* db-html-report */
    name,
    db_unique_name,
    database_role,
    protection_mode,
    protection_level,
    switchover_status,
    dataguard_broker,
    guard_status
from v$database;

prompt <h2>Data Guard — Configuration Members (V$DATAGUARD_CONFIG)</h2>

select /* db-html-report */
    db_unique_name,
    parent_dbun,
    dest_role
from v$dataguard_config
order by dest_role, db_unique_name;
