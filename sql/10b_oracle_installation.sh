prompt <h2>lscpu </h2>
prompt <pre>
host lscpu
prompt </pre>
exit


# inventory.xml
ORA_INVENTORY=$(cat /etc/oraInst.loc | grep inventory_loc | cut -d= -f2)
cat $ORA_INVENTORY/ContentsXML/inventory.xml >> ${HTML_FILE}

# opatch 
ORA_HOME=$(cat /etc/oratab | egrep -v "^$|^#" | cut -d: -f2 | sort -u)
for OH in ${ORA_HOME}
do 
	export ORACLE_HOME=${ORA_HOME}; ${ORA_HOME}/OPatch/opatch lspatches >> ${HTML_FILE}
done

