prompt <h2>Database Parameters</h2>

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