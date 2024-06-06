prompt <h2>Liste des PLuggables Databases</h2>

SELECT
    p.con_id,
    p.dbid,
    p.name,
    p.open_mode,
    p.restricted,
    p.open_time,
    p.application_root,
    p.application_pdb,
    p.application_seed
FROM
    v$pdbs p
ORDER BY
    con_id;