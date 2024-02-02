PRO <h2>Configuratiom ASM</h2>

SELECT
    dg.name,
    dg.state,
    dg.type,
    dg.total_mb,
    dg.free_mb,
    dg.usable_file_mb,
    compatibility,
    dg.database_compatibility
FROM
    v$asm_diskgroup dg;

-- Viewing disks in disk groups with V$ASM_DISK

SELECT
    dg.name "Disk Grp Name",
    a.name  "Name",
    a.failgroup,
    a.path,
    a.os_mb,
    a.total_mb,
    a.free_mb,
    a.cold_used_mb,
    a.header_status,
    a.mode_status,
    a.state,
    a.redundancy,
    to_char(a.create_date, 'DD/MM/YYYY HH24:MI') "Create Date"
FROM
    v$asm_disk      a,
    v$asm_diskgroup dg
WHERE
    a.group_number = dg.group_number
ORDER BY
    dg.name,
    a.name
;

-- Viewing disk group clients with V$ASM_CLIENT

SELECT
    dg.name            AS diskgroup,
    c.instance_name    AS instance,
    db_name            AS dbname,
    software_version   AS software,
    compatible_version AS compatible
FROM
    v$asm_diskgroup dg,
    v$asm_client    c
WHERE
    dg.group_number = c.group_number;