prompt <h2>Détail des datafiles : </h2>
SELECT  
       x.file_name, x.file_id, x.tablespace_name, 
       round(x.bytes/1024/1024,0) "Bytes_Mo", x.status, x.autoextensible, 
       round(x.maxbytes/1024/1024/1024,0) "MaxBytes_Go", x.online_status
  FROM dba_data_files x
 ORDER BY
	   x.file_name;

prompt <h2>Existance de blocks corrompus :</h2>
select * from v$database_block_corruption;
exit