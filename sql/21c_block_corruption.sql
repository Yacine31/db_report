prompt <h2>Existance de blocks corrompus :</h2>

select /* db-html-report */
    *
FROM
    V$DATABASE_BLOCK_CORRUPTION;