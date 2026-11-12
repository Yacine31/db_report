prompt <h2>Password File Users (V$PWFILE_USERS)</h2>
-- Lit une vue V$ : reste disponible sur une base montee (standby).

-- SQL*Plus tronque le titre a la largeur de la colonne : on elargit les colonnes courtes
COL common FORMAT A6
COL sysdba FORMAT A6
COL sysoper FORMAT A7
COL sysasm FORMAT A6
COL sysbackup FORMAT A9
COL sysdg FORMAT A5
COL syskm FORMAT A5
COL authentication_type FORMAT A19

select /* db-html-report */
    *
from v$pwfile_users
order by username;
