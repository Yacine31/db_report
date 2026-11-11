prompt <h2>Database Parameters</h2>

COL display_value ENTMAP ON

select /* db-html-report */
    NAME,
    DISPLAY_VALUE,
    DESCRIPTION,
    UPDATE_COMMENT
FROM
    GV$PARAMETER
WHERE
    ISDEFAULT='FALSE' 
ORDER BY
    NAME;