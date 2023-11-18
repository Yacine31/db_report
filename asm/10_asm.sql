PRO <h2>Configuratiom ASM</h2>

SELECT 
       *
  FROM v$.asm_attribute
 ORDER BY
       1, 2
;

prompt <h2>ASM Client</h2>
SELECT 
       *
  FROM v$.asm_client
 ORDER BY
       1, 2
;


prompt <h2>ASM Template</h2>
SELECT 
       *
  FROM v$.asm_template
 ORDER BY
       1, 2
;


prompt <h2>ASM Disk Group</h2>
SELECT 
       *
  FROM v$.asm_diskgroup
 ORDER BY
       1, 2
;


prompt <h2>ASM Disk Group Stat</h2>
SELECT 
       *
  FROM v$.asm_diskgroup_stat
 ORDER BY
       1, 2
;

prompt <h2>ASM Disk</h2>
SELECT 
       *
  FROM v$.asm_disk
 ORDER BY
       1, 2
;

prompt <h2>ASM Disk Stat</h2>
SELECT 
       *
  FROM v$.asm_disk_stat
 ORDER BY
       1, 2
;

prompt <h2>ASM Disk IO Stats</h2>
SELECT 
       *
  FROM &&gv_object_prefix.asm_disk_iostat
 ORDER BY
       1, 2, 3, 4, 5
;

prompt <h2>ASM File</h2>
SELECT 
       *
  FROM v$.asm_file
;

prompt <h2>Files Count per Disk Group</h2>
select 
count(*) files, name disk_group, 'Datafile' file_type
from
(select regexp_substr(name, '[^/]+', 1, 1) name from v$.datafile)
group by name
union all
select count(*) files, name disk_group, 'Tempfile' file_type
from
(select regexp_substr(name, '[^/]+', 1, 1) name from v$.tempfile)
group by name
order by 1 desc, 2, 3
;

prompt <h2>Data and Temp Files Count per Disk Group</h2>
select 
count(*) files, name disk_group
from
(select regexp_substr(name, '[^/]+', 1, 1) name from v$.datafile
union all
select regexp_substr(name, '[^/]+', 1, 1) name from v$.tempfile)
group by name
order by 1 desc
;

