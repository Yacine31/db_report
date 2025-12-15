prompt <h2>Schema Size (MB)</h2>

select /* db-html-report */
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