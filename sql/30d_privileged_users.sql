-- db-report: requires-open
prompt <h2>Accounts with a Default Password</h2>
-- Aucune ligne = aucun compte avec un mot de passe par defaut connu.

-- SQL*Plus tronque le titre a la largeur de la colonne : on elargit les colonnes courtes
COL oracle_maintained FORMAT A17
COL admin_option FORMAT A12
COL default_role FORMAT A12
COL common FORMAT A6

select /* db-html-report */
    c.name              "DB/PDB Name",
    d.username,
    u.account_status,
    u.oracle_maintained
from cdb_users_with_defpwd d
join cdb_users u
  on u.con_id = d.con_id and u.username = d.username
left join v$containers c on c.con_id = d.con_id
order by c.name, d.username;

prompt <h2>Grantees of the DBA Role</h2>

select /* db-html-report */
    c.name              "DB/PDB Name",
    p.grantee,
    p.admin_option,
    p.default_role,
    p.common
from cdb_role_privs p
left join v$containers c on c.con_id = p.con_id
where p.granted_role = 'DBA'
order by c.name, p.grantee;
