prompt <h2>Top SQL</h2>

alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS';

col sql_id head sql_id
col elapsed FORMAT 99999999 head "elapsed (second)"
col sql_text head sql_text entmap on
col cpu_time FORMAT 99999999 head "cpu_time (second)"
col buffer_gets head buffer_gets
col disk_reads head disk_reads
col physical_read_mb FORMAT 99999999.00 head physical_read_mb
col executions FORMAT 99999999 head executions
col rows_processed head rows_processed
col last_active_time head last_active_time
col module head module

-- gv$sqlstats contient une seule ligne par (inst_id, sql_id) : pas de jointure avec gv$sql,
-- qui multipliait les lignes par le nombre de curseurs enfants.
select /* db-html-report */
  t.*,
  (select max(b.module) from gv$sql b where b.inst_id = t.inst_id and b.sql_id = t.sql_id) as module
from (
select 
  a.inst_id, 
  a.sql_id,
  a.elapsed_time / 1000000 as elapsed,
  substrb(translate(a.sql_text, chr(10)||chr(13)||chr(9), '   '),1,55) as sql_text,
  a.cpu_time / 1000000 as cpu_time,
  a.buffer_gets, -- Lecture en memoire
  a.disk_reads, -- Lecture sur disque
  a.physical_read_bytes/1024/1024 as physical_read_mb,
  a.executions,
  a.rows_processed,
  a.last_active_time -- Last time the statistics of a contributing cursor were updated
from   gv$sqlstats a
order by a.elapsed_time desc
) t where rownum <= 25;

