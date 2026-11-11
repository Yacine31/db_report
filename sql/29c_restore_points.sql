prompt <h2>Restore Points</h2>
-- Un restore point garanti oublie empeche la purge des flashback logs et finit par saturer la FRA.
-- Aucune ligne = aucun restore point.

select /* db-html-report */
    name                                        "Restore Point",
    to_char(time, 'YYYY/MM/DD HH24:MI')         "Created",
    round(sysdate - cast(time as date))         "Age (days)",
    guarantee_flashback_database                "Guaranteed",
    round(storage_size / 1024 / 1024)           "Storage MB",
    scn
from v$restore_point
order by time;
