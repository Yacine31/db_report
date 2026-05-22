prompt <h2>Undo — Statistics Last 24h (V$UNDOSTAT)</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';

col begin_time      format a20
col end_time        format a20
col undoblks        head "Undo Blocks"
col txncount        head "Transactions"
col maxquerylen     head "Max Query(s)"
col maxconcurrency  head "Max Concurr."
col ssolderrcnt     head "ORA-01555"
col nospaceerrcnt   head "No Space Err"

select /* db-html-report */
    begin_time,
    end_time,
    undoblks,
    txncount,
    maxquerylen,
    maxconcurrency,
    ssolderrcnt,
    nospaceerrcnt
from v$undostat
where begin_time > sysdate - 1
order by begin_time desc;
