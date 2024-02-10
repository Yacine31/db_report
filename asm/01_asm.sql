PRO <h2>Configuratiom ASM</h2>

SELECT
    DG.NAME,
    DG.STATE,
    DG.TYPE,
    DG.TOTAL_MB,
    DG.FREE_MB,
    DG.USABLE_FILE_MB,
    COMPATIBILITY,
    DG.DATABASE_COMPATIBILITY
FROM
    V$ASM_DISKGROUP DG;
-- Viewing disks in disk groups with V$ASM_DISK

SELECT
    DG.NAME                                      "Disk Grp Name",
    A.NAME                                       "Name",
    A.FAILGROUP,
    A.PATH,
    A.OS_MB,
    A.TOTAL_MB,
    A.FREE_MB,
    A.COLD_USED_MB,
    A.HEADER_STATUS,
    A.MODE_STATUS,
    A.STATE,
    A.REDUNDANCY,
    TO_CHAR(A.CREATE_DATE, 'DD/MM/YYYY HH24:MI') "Create Date"
FROM
    V$ASM_DISK      A,
    V$ASM_DISKGROUP DG
WHERE
    A.GROUP_NUMBER = DG.GROUP_NUMBER
ORDER BY
    DG.NAME,
    A.NAME;

-- Viewing disk group clients with V$ASM_CLIENT
SELECT
    DG.NAME            AS DISKGROUP,
    C.INSTANCE_NAME    AS INSTANCE,
    DB_NAME            AS DBNAME,
    SOFTWARE_VERSION   AS SOFTWARE,
    COMPATIBLE_VERSION AS COMPATIBLE
FROM
    V$ASM_DISKGROUP DG,
    V$ASM_CLIENT    C
WHERE
    DG.GROUP_NUMBER = C.GROUP_NUMBER;