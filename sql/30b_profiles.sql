prompt <h2>DBA_Profiles </h2>

select /* db-html-report */
    *
FROM
    DBA_PROFILES
ORDER BY
    PROFILE,
    RESOURCE_NAME;