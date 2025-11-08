prompt <h2>Curseurs par Session (sans les users SYS, SYSTEM, SYSMAN)</h2>

select /* axiome */ c.sid, s.username, count(*) open_cursors
    from gv$open_cursor c, gv$session s
    where s.sid = c.sid
    and s.username is not null and s.username not like 'SYS%'
    group by c.sid, s.username
;