prompt <h2>Paramèters de la base de données : </h2>
select NAME, DISPLAY_VALUE, DESCRIPTION, UPDATE_COMMENT from v$parameter where ISDEFAULT='FALSE' order by name;
