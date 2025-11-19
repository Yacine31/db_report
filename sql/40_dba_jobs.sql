prompt <h2>Liste des derniers jobs dans : CDB_SCHEDULER_JOB_LOG </h2>

ALTER SESSION SET NLS_DATE_FORMAT='YYYY/MM/DD HH24:MI:SS';

select /* db-html-report */
* from 
(
    select log_date, owner, job_name, status
    from CDB_SCHEDULER_JOB_LOG
    order by log_date desc
) where rownum <= 20
;