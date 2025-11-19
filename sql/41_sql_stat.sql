prompt <h2>Top SQL</h2>

select /* db-html-report */ 
* from (
select 
  a.inst_id, 
  a.sql_id,
  to_char(numtodsinterval(a.elapsed_time/ 1000000, 'SECOND'), 'HH24:MI') as elapsed,
  substrb(replace(a.sql_text,'',' '),1,55) as sql_text,
  a.buffer_gets, -- Lecture en memoire
  a.disk_reads, -- Lecture sur disque
  round(a.physical_read_bytes /1024/1024) as physical_read_MB,
  a.executions,
  a.rows_processed,
  to_char(a.last_active_time, 'DD/MM/YYYY HH24:MI:SS') as last_active_time, -- Last time the statistics of a contributing cursor were updated
  b.module
from   gv$sqlstats a, gv$sql b 
where  a.sql_id=b.sql_id
order by a.elapsed_time desc
) where rownum <= 25;