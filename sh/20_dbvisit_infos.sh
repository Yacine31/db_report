# dbvisit
echo "<h2>Process DBVisit</h2>"
echo "<pre>"
ps -ef | grep dbvctl
echo "</pre>"

echo "<h2>dbvctl gap report</h2>"
export DBV_HOME=/usr/dbvisit/standbymp/oracle
for db in ${DBV_HOME}/conf/dbv_*.env
do
	echo "<pre>"
	${DBV_HOME}/dbvctl -d $db -i
	echo "</pre>"
	echo "<br>"
done
