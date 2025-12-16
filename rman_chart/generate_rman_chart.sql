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
prompt   google.setOnLoadCallback(drawChart_&db_sid);
prompt   function drawChart_&db_sid() {
prompt     var data = new google.visualization.DataTable();
prompt     data.addColumn('datetime', 'Date');
prompt     data.addColumn('number', 'Input Go');
prompt     data.addColumn('number', 'Output Go');
prompt     data.addColumn('number', 'Duration (minutes)');
prompt     data.addRows([

-- This is where the SQL query will inject the data for the chart
SELECT
     decode(rownum, 1, '', ','),
     '[new Date(' ||
         TO_CHAR(B.START_TIME, 'YYYY') || ',' ||
         (TO_NUMBER(TO_CHAR(B.START_TIME, 'MM')) - 1) || ',' ||
         TO_CHAR(B.START_TIME, 'DD') || ',' ||      -- Séparer le jour
         TO_CHAR(B.START_TIME, 'HH24') || ',' ||    -- Séparer l'heure
         TO_CHAR(B.START_TIME, 'MI') || ',' ||      -- Séparer les minutes
         TO_CHAR(B.START_TIME, 'SS') ||             -- Séparer les secondes
     '),' ||
     NVL(REPLACE(TO_CHAR(B.INPUT_GO), ',', '.'), 'null') || ',' ||        -- Remplacer virgule par point, gérer NULL
     NVL(REPLACE(TO_CHAR(B.OUTPUT_GO), ',', '.'), 'null') || ',' ||       -- Remplacer virgule par point, gérer NULL
     NVL(REPLACE(TO_CHAR(B.DURATION_MINUTES), ',', '.'), 'null') || ']'   -- Remplacer virgule par point, gérer NULL
 FROM
     (
         SELECT
             B.START_TIME,
             ROUND(NVL(B.INPUT_BYTES, 0) / (1024*1024*1024), 2) AS INPUT_GO,
             ROUND(NVL(B.OUTPUT_BYTES, 0) / (1024*1024*1024), 2) AS OUTPUT_GO,
             ROUND(NVL(B.ELAPSED_SECONDS, 0) / 60, 2) AS DURATION_MINUTES
         FROM
             V$RMAN_BACKUP_JOB_DETAILS B
         WHERE
             B.START_TIME > ( SYSDATE - 90 )
             -- AND B.STATUS = 'COMPLETED'
         ORDER BY
             B.START_TIME ASC
     ) B;

-- SELECT
--     decode(rownum, 1, '', ','),
--     '[new Date(' ||
--         TO_CHAR(B.START_TIME, 'YYYY') || ',' ||
--         (TO_NUMBER(TO_CHAR(B.START_TIME, 'MM')) - 1) || ',' ||
--         TO_CHAR(B.START_TIME, 'DD,HH24,MI,SS') ||
--     '),' ||
--     B.INPUT_GO || ',' ||
--     B.OUTPUT_GO || ',' ||
--     B.DURATION_MINUTES || ']'
-- FROM
--     (
--         SELECT
--             B.START_TIME,
--             ROUND(NVL(B.INPUT_BYTES, 0) / (1024*1024*1024), 2) AS INPUT_GO,
--             ROUND(NVL(B.OUTPUT_BYTES, 0) / (1024*1024*1024), 2) AS OUTPUT_GO,
--             ROUND(NVL(B.ELAPSED_SECONDS, 0) / 60, 2) AS DURATION_MINUTES
--         FROM
--             V$RMAN_BACKUP_JOB_DETAILS B
--         WHERE
--             B.START_TIME > ( SYSDATE - 90 )
--             -- AND B.STATUS = 'COMPLETED'
--         ORDER BY
--             B.START_TIME ASC
--     ) B;

prompt     ]);
prompt
prompt     var options = {
prompt       title: 'RMAN Backup History for Database &db_sid',
prompt       curveType: 'function',
prompt       legend: { position: 'bottom' },
prompt       height: 600,
prompt       series: {
prompt         0: {targetAxisIndex: 0, color: '#3366cc'},
prompt         1: {targetAxisIndex: 0, color: '#109618'},
prompt         2: {targetAxisIndex: 1, color: '#dc3912'}
prompt       },
prompt       vAxes: {
prompt         0: {title: 'Size (Go)', format: 'short', viewWindow: {min: 0}},
prompt         1: {title: 'Duration (minutes)', format: 'short', viewWindow: {min: 0}}
prompt       },
prompt       hAxis: {
prompt         title: 'Date',
prompt         format: 'dd/MM/yy HH:mm'
prompt       },
prompt       explorer: {
prompt         actions: ['dragToZoom', 'rightClickToReset'],
prompt         axis: 'horizontal'
prompt       }
prompt     };
prompt
prompt     var chart = new google.visualization.LineChart(document.getElementById('chart_div_&db_sid'));
prompt     chart.draw(data, options);
prompt   }
prompt </script>
prompt <div id="chart_div_&db_sid" style="width: 95%; height: 600px;"></div>

-- Reset settings
set feedback on
set verify on
set heading on