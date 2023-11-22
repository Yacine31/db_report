prompt <h2>Détail des datafiles : </h2>

COL file_id HEAD "File ID"
COL file_name HEAD "Datafile"
COL tablespace_name FORMAT A20 HEAD "Tablespace"

COL bytes FORMAT 99999999.00 HEAD "Size MB"
COL maxbytes FORMAT 99999999.00 HEAD "MaxSize MB"
COL Pct_Used FORMAT 999.00 HEAD "% Used"


COL autoextensible FORMAT A15 HEAD "Auto Extensible"
COL status head "Status"
COL online_status format a15 head "Online Status"

SELECT  
       file_id, file_name, tablespace_name, 
       round(bytes/1024/1024,0) bytes,  
       round(maxbytes/1024/1024,0) maxbytes, 
       round(100*bytes/maxbytes) Pct_Used,
       online_status,
       status, autoextensible
  FROM dba_data_files 
 ORDER BY
          file_name;

prompt <h2>Existance de blocks corrompus :</h2>
select * from v$database_block_corruption;
