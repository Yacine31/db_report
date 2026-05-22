#! /bin/sh

# Retourne YES si la base participe à une configuration Data Guard, NO sinon.
# Cas couverts : standby (tout type) ou primary avec au moins un standby déclaré.
echo "
SET PAGES 999 FEEDBACK OFF HEAD OFF
select case
  when database_role <> 'PRIMARY' then 'YES'
  when (select count(*) from v\$dataguard_config) > 1 then 'YES'
  else 'NO'
end
from v\$database;
exit" | sqlplus -s / as sysdba
