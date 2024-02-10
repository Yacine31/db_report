prompt <h2>Statut des jobs autotask </h2>

SELECT
    CLIENT_NAME,
    STATUS,
    ATTRIBUTES,
    SERVICE_NAME
FROM
    DBA_AUTOTASK_CLIENT;