prompt <h2>Fast Recovery Area Usage</h2>
select 'Taille FRA MiB' as property, p.value / 1024 / 1024  as value from 
v$parameter p WHERE name = 'db_recovery_file_dest_size'
union all
select 'Espace utilise MiB' as property, round((p.value * tot_pct / 100) / 1024 / 1024, 0) as value from 
( SELECT SUM(percent_space_used) tot_pct FROM v$flash_recovery_area_usage ) , V$PARAMETER P 
WHERE name = 'db_recovery_file_dest_size'
union all
select 'Pourcentage utilise' as property, tot_pct  as value from 
( SELECT SUM(percent_space_used) tot_pct FROM v$flash_recovery_area_usage ) 
;
