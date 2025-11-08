prompt <h2>Dictionary Stats / Fixed Objects Stats</h2>

select /* axiome */
	TO_CHAR(MAX(END_TIME), 'dd/mm/yyyy hh24:mi') LATEST,
	OPERATION
FROM
	DBA_OPTSTAT_OPERATIONS
WHERE
	OPERATION IN ('gather_dictionary_stats', 'gather_fixed_objects_stats')
GROUP BY
	OPERATION;