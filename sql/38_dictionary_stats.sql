prompt <h2>Dictionary & Fixed Obj Stats</h2>

select /* db-html-report */
	TO_CHAR(MAX(END_TIME), 'dd/mm/yyyy hh24:mi') LATEST,
	OPERATION
FROM
	DBA_OPTSTAT_OPERATIONS
WHERE
	OPERATION IN ('gather_dictionary_stats', 'gather_fixed_objects_stats')
GROUP BY
	OPERATION;