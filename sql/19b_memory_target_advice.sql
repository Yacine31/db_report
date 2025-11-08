prompt <h2>SGA Target Advice</h2>

select /* axiome */
    *
FROM
    GV$SGA_TARGET_ADVICE;

prompt <h2>PGA Target Advice</h2>

SELECT
    *
FROM
    GV$PGA_TARGET_ADVICE;

prompt <h2>Memory Target Advice</h2>
SELECT
    *
FROM
    GV$MEMORY_TARGET_ADVICE;