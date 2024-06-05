#! /bin/sh

# Retourne YES ou NO selon que la base est une CDB ou non
echo "
SET PAGES 999 FEEDBACK OFF HEAD OFF
select cdb from v\$database;
exit" | sqlplus -s / as sysdba