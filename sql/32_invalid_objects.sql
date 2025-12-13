prompt <h2>Invalid objects</h2>

select /* db-html-report */
    OWNER,
    COUNT(*) "Invalid Objects"
FROM
    DBA_OBJECTS
WHERE
    STATUS <> 'VALID'
GROUP BY
    OWNER
ORDER BY
    OWNER;
