prompt <h2>Détail des datafiles : </h2>

COL file_name HEAD "Datafile"
COL file_id HEAD "File ID"
COL TABLESPACE_NAME FORMAT A20 HEAD "Tablespace"
COL autoextensible FORMAT A15 HEAD "Auto Extensible"
COL status head "Statut"
COL online_status format a15 head "Online Statut"

SELECT  
       file_name, file_id, tablespace_name, 
       round(bytes/1024/1024,0) "Bytes Mo", status, autoextensible, 
       round(maxbytes/1024/1024,0) "MaxBytes Mo", online_status "Online Statut"
  FROM dba_data_files 
 ORDER BY
	   file_name;

prompt <h2>Existance de blocks corrompus :</h2>
select * from v$database_block_corruption;
