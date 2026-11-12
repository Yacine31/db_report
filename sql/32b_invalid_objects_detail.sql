-- db-report: requires-open
prompt <h2>Invalid Objects Detail (first 500)</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

select /* db-html-report */
    *
from (
    select
        c.name              "DB/PDB Name",
        o.owner,
        o.object_type,
        o.object_name,
        o.status,
        o.last_ddl_time
    from cdb_objects o
    left join v$containers c on c.con_id = o.con_id
    where o.status <> 'VALID'
    order by c.name, o.owner, o.object_type, o.object_name
)
where rownum <= 500;
