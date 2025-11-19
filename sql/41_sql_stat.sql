prompt <h2>Top SQL</h2>

alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS';

select /* db-html-report */ 
* from (
select 
  a.inst_id, 
  a.sql_id,
  round(elapsed_time / 1000000) as elapsed,
  substrb(replace(a.sql_text,'',' '),1,55) as sql_text,
  round(a.cpu_time / 1000000) as cpu_time,
  a.buffer_gets, -- Lecture en memoire
  a.disk_reads, -- Lecture sur disque
  a.physical_read_bytes,
  a.executions,
  a.rows_processed,
  a.last_active_time, -- Last time the statistics of a contributing cursor were updated
  b.module
from   gv$sqlstats a, gv$sql b 
where  a.sql_id=b.sql_id
order by a.elapsed_time desc
) where rownum <= 25;