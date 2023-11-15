prompt <h2>Database supplemental logging :</h2>

col data_mining for a15
col data_pkey for a15
col data_uniq_key for a15
col data_fk for a15
col data_all for a15
col data_pl for a15
col force_logging for a15
SELECT 
	force_logging,
	supplemental_log_data_min data_mining, 
	supplemental_log_data_pk data_pkey, 
	supplemental_log_data_ui data_uniq_key, 
	supplemental_log_data_fk data_fk, 
	supplemental_log_data_all data_all, 
	supplemental_log_data_pl data_pl
FROM v$database;

