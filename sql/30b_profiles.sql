prompt <h2>DBA Profiles</h2>

select /* db-html-report */
    *
FROM
    DBA_PROFILES
ORDER BY
    PROFILE,
    RESOURCE_NAME;