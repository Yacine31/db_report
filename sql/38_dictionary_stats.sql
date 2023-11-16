prompt <h2>Dictionary Stats / Fixed Objects Stats</h2>

SELECT
	to_char(max(end_time),'dd/mm/yyyy hh24:mi') latest, operation
FROM
	dba_optstat_operations
WHERE
	operation in ('gather_dictionary_stats', 'gather_fixed_objects_stats')
GROUP BY
	operation;
