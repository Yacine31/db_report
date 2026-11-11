prompt <h2>Dictionary and Fixed Obj Stats</h2>
-- Une ligne par operation, meme si elle n'a jamais ete executee.

select /* db-html-report */
	o.operation,
	nvl(to_char(max(d.end_time), 'dd/mm/yyyy hh24:mi'),
	    'No run found in DBA_OPTSTAT_OPERATIONS (never gathered, or history purged)') latest
from
	(select 'gather_dictionary_stats' operation from dual
	 union all
	 select 'gather_fixed_objects_stats' from dual) o
	left join dba_optstat_operations d on d.operation = o.operation
group by
	o.operation
order by
	o.operation;
