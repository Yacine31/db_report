prompt <h2>Paramèters de la base de données : </h2>

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