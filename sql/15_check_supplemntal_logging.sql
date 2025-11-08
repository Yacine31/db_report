prompt <h2>Database supplemental logging :</h2>

select /* axiome */ 'force_logging' as property, force_logging as value from v$database
union all
select 'supplemental_log_data_min' as property, supplemental_log_data_min as value from v$database
union all
select 'supplemental_log_data_pk' as property, supplemental_log_data_pk as value from v$database
union all
select 'supplemental_log_data_ui' as property, supplemental_log_data_ui as value from v$database
union all
select 'supplemental_log_data_fk' as property, supplemental_log_data_fk as value from v$database
union all
select 'supplemental_log_data_all' as property, supplemental_log_data_all as value from v$database
union all
select 'supplemental_log_data_pl' as property, supplemental_log_data_pl as value from v$database

