PRO <h2>Configuratiom ASM</h2>

select * from GV_$ASM_DISKGROUP;


select 
    a.inst_id,
    a.group_number,
    a.disk_number,
    a.header_status,
    a.mode_status,
    a.state,
    a.redundancy,
    a.os_mb,
    a.total_mb,
    a.free_mb,
    a.cold_used_mb,
    a.name,
    a.failgroup,
    a.path,
    a.create_date
from GV_$ASM_DISK a;

