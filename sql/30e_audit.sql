prompt <h2>Audit Settings</h2>

select /* db-html-report */
    name            as property,
    display_value   as value
from v$parameter
where name like 'audit%'
union all
select 'Unified Auditing (V$OPTION)', value
from v$option
where parameter = 'Unified Auditing'
order by 1;
