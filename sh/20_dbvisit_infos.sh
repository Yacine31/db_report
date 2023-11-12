# dbvisit
echo "<h2>Process DBVisit</h2>"
echo "<pre>"
ps -ef | grep dbvctl
echo "</pre>"

echo "<h2>dbvctl gap report</h2>"
export DBV_HOME=/usr/dbvisit/standbymp/oracle
cd ${DBV_HOME}/conf 
ls -1 dbv_*.env | sed 's/dbv_//g' | sed 's/.env//g' | while read db
do
	echo "<pre>"
	${DBV_HOME}/dbvctl -d $db -i
	echo "</pre>"
	echo "<br>"
done
