prompt <h2>Top 20 Segments by Size</h2>

select /* db-html-report */
    *
from (
    select
        c.name                              "DB/PDB Name",
        s.owner                             "Owner",
        s.segment_name                      "Segment",
        s.partition_name                    "Partition",
        s.segment_type                      "Type",
        s.tablespace_name                   "Tablespace",
        round(s.bytes / 1024 / 1024)        "Size MB"
    from cdb_segments s
    left join v$containers c on c.con_id = s.con_id
    order by s.bytes desc
)
where rownum <= 20;
