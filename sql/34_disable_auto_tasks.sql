prompt <h2>Autotask Job Status</h2>

select /* db-html-report */
    CLIENT_NAME,
    STATUS,
    ATTRIBUTES,
    SERVICE_NAME
FROM
    DBA_AUTOTASK_CLIENT;