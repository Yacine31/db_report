-- db-report: requires-open
prompt <h2>Datafile Space per Directory (current vs autoextend maximum)</h2>
-- A comparer avec "df -h" du rapport serveur : si "Max Size MB" depasse la taille du
-- filesystem (ou du disk group), l'autoextend ne pourra pas aller jusqu'au bout.

select /* db-html-report */
    substr(file_name, 1, instr(file_name, '/', -1))                              "Directory",
    count(*)                                                                     "Files",
    round(sum(bytes) / 1024 / 1024)                                              "Current Size MB",
    round(sum(decode(autoextensible, 'YES', greatest(maxbytes, bytes), bytes)) / 1024 / 1024) "Max Size MB",
    round(sum(decode(autoextensible, 'YES', greatest(maxbytes, bytes), bytes) - bytes) / 1024 / 1024) "Possible Growth MB"
from (
    select file_name, bytes, autoextensible, maxbytes from cdb_data_files
    union all
    select file_name, bytes, autoextensible, maxbytes from cdb_temp_files
)
group by substr(file_name, 1, instr(file_name, '/', -1))
order by 1;
