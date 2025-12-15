prompt <h2>Resource Limits</h2>

select /* db-html-report */
    *
FROM
    GV$RESOURCE_LIMIT
WHERE
    RESOURCE_NAME IN ( 'processes', 'sessions' )
ORDER BY
    RESOURCE_NAME,
    INST_ID;