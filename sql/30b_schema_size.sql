prompt <h2>Taille des objets par schéma (Mo):</h2>
select
    ds.owner "Owner",
    round(sum(ds.bytes) / 1024 / 1024) "Schema Size MB",
    du.default_tablespace "Default Tablespace"
from
    dba_segments ds,
    dba_users du
where
    ds.OWNER = du.USERNAME
group by
    ds.owner,
    du.default_tablespace
order by
    ds.owner
;
