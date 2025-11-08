prompt <h2>SYSAUX Occupants</h2>

select /* axiome */ /*+  NO_MERGE  */
     V.*,
     ROUND(V.SPACE_USAGE_KBYTES / POWER(10, 6), 3) SPACE_USAGE_GBS
FROM
     V$SYSAUX_OCCUPANTS V
ORDER BY
     1;