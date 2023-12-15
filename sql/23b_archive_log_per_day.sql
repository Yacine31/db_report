prompt <h2>Taille des redolog par jour :</h2>
select
        to_char(first_time, 'YYYY/MM/dd') "Jour",
        count(*) "Nbr de fichiers",
        ROUND(sum(BLOCKS*BLOCK_SIZE)/1024/1024, 0) "Taille_Mo"
from v$archived_log
where first_time > systimestamp - 30
group by to_char(first_time, 'YYYY/MM/dd')
order by to_char(first_time, 'YYYY/MM/dd')
;
