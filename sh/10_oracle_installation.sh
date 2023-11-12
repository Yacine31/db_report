# inventory.xml
echo "<h2>Inventory.xml</h2>"
echo "<pre>"
ORA_INVENTORY=$(cat /etc/oraInst.loc | grep inventory_loc | cut -d= -f2)
cat $ORA_INVENTORY/ContentsXML/inventory.xml | grep "<HOME NAME=" | awk '{print $2 " " $3}'
echo "</pre>"

# opatch 
echo "<h2>Opatch lspatches</h2>"
cat /etc/oratab | egrep -v "^$|^#" | cut -d: -f2 | sort -u | while read oh
do 
	echo "<pre>"
	echo "ORACLE=HOME="$oh
	echo ""
	export ORACLE_HOME=$oh
	$oh/OPatch/opatch lspatches
	echo "</pre>"
done

