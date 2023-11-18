prompt <h2>Taille des objets par schéma (Mo):</h2>
select
    ds.owner owner,
    round(sum(ds.bytes) / 1024 / 1024) "schema size mega",
    du.default_tablespace "default tablespace"
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
