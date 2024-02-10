prompt <h2>Taille des objets par schéma (Mo):</h2>

SELECT
    DS.OWNER                           "Owner",
    ROUND(SUM(DS.BYTES) / 1024 / 1024) "Schema Size MB",
    DU.DEFAULT_TABLESPACE              "Default Tablespace"
FROM
    DBA_SEGMENTS DS,
    DBA_USERS    DU
WHERE
    DS.OWNER = DU.USERNAME
GROUP BY
    DS.OWNER,
    DU.DEFAULT_TABLESPACE
ORDER BY
    DS.OWNER;