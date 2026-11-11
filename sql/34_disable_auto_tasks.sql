prompt <h2>Autotask Job Status</h2>

-- DBA_AUTOTASK_OPERATION et non DBA_AUTOTASK_CLIENT : cette derniere peut prendre
-- plusieurs dizaines de secondes sur une base avec un long historique de taches.
select /* db-html-report */
    CLIENT_NAME,
    OPERATION_NAME,
    STATUS,
    ATTRIBUTES
FROM
    DBA_AUTOTASK_OPERATION
ORDER BY
    CLIENT_NAME;
