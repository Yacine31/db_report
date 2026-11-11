prompt <h2>DBA Users</h2>
-- CDB_USERS : couvre CDB$ROOT et les PDB ouvertes (une seule ligne de conteneur sur une non-CDB)

ALTER SESSION SET NLS_DATE_FORMAT ='YYYY/MM/DD HH24:MI';

-- SQL*Plus tronque le titre a la largeur de la colonne : on elargit les colonnes courtes
COL ORACLE_MAINTAINED FORMAT A17
COL COMMON FORMAT A6

select /* db-html-report */
     C.NAME                                         "DB/PDB Name",
     U.USERNAME,
     U.USER_ID,
     U.ACCOUNT_STATUS,
     U.LOCK_DATE,
     U.EXPIRY_DATE,
     U.DEFAULT_TABLESPACE,
     U.TEMPORARY_TABLESPACE,
     U.CREATED,
     TO_CHAR(U.LAST_LOGIN, 'YYYY/MM/DD HH24:MI')    LAST_LOGIN,
     U.PROFILE,
     U.PASSWORD_VERSIONS,
     U.ORACLE_MAINTAINED,
     U.COMMON
FROM
     CDB_USERS U
     LEFT JOIN V$CONTAINERS C ON C.CON_ID = U.CON_ID
ORDER BY
     C.NAME,
     U.USERNAME;
