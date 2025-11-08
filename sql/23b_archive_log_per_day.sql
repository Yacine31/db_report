prompt <h2>Taille des redolog par jour :</h2>

select /* axiome */
        TO_CHAR(FIRST_TIME, 'YYYY/MM/dd')          "Jour",
        COUNT(*)                                   "Nbr de fichiers",
        ROUND(SUM(BLOCKS*BLOCK_SIZE)/1024/1024, 0) "Taille_Mo"
FROM
        V$ARCHIVED_LOG
WHERE
        FIRST_TIME > SYSTIMESTAMP - 30
GROUP BY
        TO_CHAR(FIRST_TIME, 'YYYY/MM/dd')
ORDER BY
        TO_CHAR(FIRST_TIME, 'YYYY/MM/dd');