-- Fragment HTML pour une base : appelle rmanChart("<SID>", [lignes]) defini dans
-- rman_chart/00_chart_html_header.html (graphique SVG embarque, sans dependance externe).
-- La variable &db_sid est definie par generate_rman_chart.sh.

-- SQL*Plus settings for a clean fragment output
set feedback off
set verify off
set pause off
set timing off
set echo off
set heading off
set pages 0
set trimspool on
set newpage none
set linesize 3000

-- Note: No spool, no HTML head. This is just a fragment.

prompt <script type="text/javascript">
prompt rmanChart("&db_sid", [

-- Une ligne par sauvegarde : ["date ISO", input_gb, output_gb, duration_min],
-- Le point decimal est force pour rester du JavaScript valide quel que soit le NLS de la base.
SELECT
     '["' || TO_CHAR(B.START_TIME, 'YYYY-MM-DD"T"HH24:MI:SS') || '",' ||
     TO_CHAR(B.INPUT_GB,         'FM99999999990.00', 'NLS_NUMERIC_CHARACTERS=''.,''') || ',' ||
     TO_CHAR(B.OUTPUT_GB,        'FM99999999990.00', 'NLS_NUMERIC_CHARACTERS=''.,''') || ',' ||
     TO_CHAR(B.DURATION_MINUTES, 'FM99999999990.00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '],'
 FROM
     (
         SELECT
             B.START_TIME,
             ROUND(NVL(B.INPUT_BYTES, 0) / (1024*1024*1024), 2) AS INPUT_GB,
             ROUND(NVL(B.OUTPUT_BYTES, 0) / (1024*1024*1024), 2) AS OUTPUT_GB,
             ROUND(NVL(B.ELAPSED_SECONDS, 0) / 60, 2) AS DURATION_MINUTES
         FROM
             V$RMAN_BACKUP_JOB_DETAILS B
         WHERE
             B.START_TIME > ( SYSDATE - 90 )
             -- AND B.STATUS = 'COMPLETED'
         ORDER BY
             B.START_TIME ASC
     ) B;

prompt ]);
prompt </script>

-- Reset settings
set feedback on
set verify on
set heading on
