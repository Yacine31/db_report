# inventory.xml
echo "<h2>Inventory.xml</h2>"
echo "<pre>"
ORA_INVENTORY=$(cat /etc/oraInst.loc | grep inventory_loc | cut -d= -f2)
cat $ORA_INVENTORY/ContentsXML/inventory.xml | grep "<HOME NAME=" | awk '{print $2 " " $3}'
echo "</pre>"

# opatch 
echo "<h2>Opatch lspatches</h2>"
echo "<pre>"
ORA_HOME=$(cat /etc/oratab | egrep -v "^$|^#" | cut -d: -f2 | sort -u)
for OH in ${ORA_HOME}
do 
	export ORACLE_HOME=${ORA_HOME}; ${ORA_HOME}/OPatch/opatch lspatches 
done
echo "</pre>"

