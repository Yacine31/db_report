prompt <h2>Paramètres NLS au niveau de la base de données :</h2>

-- SELECT * FROM NLS_DATABASE_PARAMETERS ORDER BY PARAMETER;
select * from gv$nls_parameters order by PARAMETER ;