prompt <h2>Cursors per Session</h2>

select /* db-html-report */ c.inst_id, c.sid, s.username, count(*) open_cursors
    from gv$open_cursor c, gv$session s
    where s.sid = c.sid
    and s.inst_id = c.inst_id
    and s.username is not null and s.username not like 'SYS%'
    group by c.inst_id, c.sid, s.username
    order by open_cursors desc
;
