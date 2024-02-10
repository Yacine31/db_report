prompt <h2>Resource Limit (GV$RESOURCE_LIMIT)</h2>

SELECT
    *
FROM
    GV$RESOURCE_LIMIT
WHERE
    RESOURCE_NAME IN ( 'processes', 'sessions' )
ORDER BY
    RESOURCE_NAME,
    INST_ID;