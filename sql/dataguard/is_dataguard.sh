#! /bin/sh

# Retourne YES si la base fait partie d'une configuration Data Guard, NO sinon.
# Le role seul ne suffit pas : une standby geree par Dbvisit est aussi PHYSICAL STANDBY
# sans etre du Data Guard. On retient donc une configuration Data Guard reelle :
#   - broker demarre (dg_broker_start = TRUE), le cas le plus courant ;
#   - ou log_archive_config contenant DG_CONFIG ;
#   - ou une destination d'archivage active vers une autre base (TARGET = STANDBY).
# Uniquement des vues V$ : fonctionne aussi sur une base montee.
echo "
SET PAGES 999 FEEDBACK OFF HEAD OFF
select case
  when (select upper(value) from v\$parameter where name = 'dg_broker_start') = 'TRUE' then 'YES'
  when (select upper(value) from v\$parameter where name = 'log_archive_config') like '%DG_CONFIG%' then 'YES'
  when (select count(*) from v\$archive_dest where target = 'STANDBY' and status not in ('INACTIVE', 'DEFERRED')) > 0 then 'YES'
  else 'NO'
end
from dual;
exit" | sqlplus -s / as sysdba
