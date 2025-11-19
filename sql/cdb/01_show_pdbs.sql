prompt <h2>Liste des PLuggables Databases</h2>

col application_root for a25
col application_pdb for a25
col application_seed for a25

select /* db-html-report */
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