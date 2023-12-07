prompt <h2>Resource Limit (GV$RESOURCE_LIMIT)</h2>
SELECT
    *
FROM
    gv$resource_limit
WHERE
    resource_name IN ( 'processes', 'sessions' )
ORDER BY
    resource_name,
    inst_id;
