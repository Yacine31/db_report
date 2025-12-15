prompt <h2>FRA Usage Summary</h2>

select /* db-html-report */
    'Taille FRA MiB'                                  AS PROPERTY,
    P.VALUE / 1024 / 1024 AS VALUE
FROM
    V$PARAMETER P
WHERE
    NAME = 'db_recovery_file_dest_size'
UNION
ALL
SELECT
    'Espace utilise MiB'                              AS PROPERTY,
    ROUND((P.VALUE * TOT_PCT / 100) / 1024 / 1024, 0) AS VALUE
FROM
    (
        SELECT
            SUM(PERCENT_SPACE_USED) TOT_PCT
        FROM
            V$FLASH_RECOVERY_AREA_USAGE
    )           ,
    V$PARAMETER P
WHERE
    NAME = 'db_recovery_file_dest_size'
UNION
ALL
SELECT
    'Pourcentage utilise'                             AS PROPERTY,
    TOT_PCT                                           AS VALUE
FROM
    (
        SELECT
            SUM(PERCENT_SPACE_USED) TOT_PCT
        FROM
            V$FLASH_RECOVERY_AREA_USAGE
    )           ;