prompt <h2>Disabled Constraints (application schemas, first 500)</h2>
-- Schemas non maintenus par Oracle uniquement. Types : P = cle primaire, U = unique,
-- R = cle etrangere, C = check.
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

COL constraint_type FORMAT A15

select /* db-html-report */
    *
from (
    select
        c.name              "DB/PDB Name",
        k.owner,
        k.table_name,
        k.constraint_name,
        k.constraint_type,
        k.status,
        k.validated,
        k.last_change
    from cdb_constraints k
    join cdb_users u
      on u.con_id = k.con_id and u.username = k.owner and u.oracle_maintained = 'N'
    left join v$containers c on c.con_id = k.con_id
    where k.status = 'DISABLED'
    order by c.name, k.owner, k.table_name, k.constraint_name
)
where rownum <= 500;
