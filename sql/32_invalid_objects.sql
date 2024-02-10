prompt <h2>Invalid objects</h2>

SELECT
    OWNER,
    COUNT(*) "invalid objects"
FROM
    DBA_OBJECTS
WHERE
    STATUS <> 'VALID'
GROUP BY
    OWNER
ORDER BY
    OWNER;
