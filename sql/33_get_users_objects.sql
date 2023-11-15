prompt <h2>Les objets par utilisateur</h2>
select * from
(
    select owner, object_type ,count(*) as object_count from dba_objects 
    where owner not in ('ANONYMOUS','APEX_180200','APEX_INSTANCE_ADMIN_USER','APEX_PUBLIC_USER','APPQOSSYS','AUDSYS','CTXSYS','DBSFWUSER','DBSNMP','DIP','DVF','DVSYS','FLOWS_FILES','GGSYS','GSMADMIN_INTERNAL','GSMCATUSER','GSMUSER','LBACSYS','MDDATA','MDSYS','OJVMSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','REMOTE_SCHEDULER_AGENT','SI_INFORMTN_SCHEMA','SYS','SYS$UMF','SYSBACKUP','SYSDG','SYSKM','SYSRAC','SYSTEM','WMSYS','XDB','XS$NULL')
    group by owner, object_type order by owner, object_type
)
  pivot
  (
     max(object_count)
     for object_type in (
             'TABLE',
             'VIEW',
             'INDEX',
             'FUNCTION',
             'LOB',
             'PACKAGE',
             'PROCEDURE',
             'TRIGGER',
             'SYNONYM'
        )
  )
  order by owner
;


