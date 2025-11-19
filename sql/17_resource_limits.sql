prompt <h2>Resource Limit (GV$RESOURCE_LIMIT)</h2>

select /* db-html-report */
    *
FROM
    GV$RESOURCE_LIMIT
WHERE
    RESOURCE_NAME IN ( 'processes', 'sessions' )
ORDER BY
    RESOURCE_NAME,
    INST_ID;