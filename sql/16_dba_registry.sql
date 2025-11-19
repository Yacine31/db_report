prompt <h2>Fonctionnalités installées dans la base de données (DBA_REGISTRY) :</h2>

select /* db-html-report */
  *
FROM
  DBA_REGISTRY
ORDER BY
  COMP_ID;