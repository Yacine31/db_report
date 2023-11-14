# run script only if dbvctl is running

count=$(ps -ef | grep dbvctl | grep -v grep | wc -l)

if [ $count -gt 0 ]; then
	# dbvisit
	echo "<h2>Process DBVisit</h2>"
	echo "<pre>"
	ps -ef | grep dbvctl | grep -v grep 
	echo "</pre>"

	echo "<h2>dbvctl gap report</h2>"
	# export DBV_HOME=/usr/dbvisit/standbymp/oracle
	export DBV_HOME=$(dirname $(ps -ef | grep dbvctl | grep -v grep | awk '{print $8}' | sort -u))

	echo "<pre>"
	${DBV_HOME}/dbvctl -d ${ORACLE_SID} -i
	echo "</pre>"


	# cd ${DBV_HOME}/conf 
	# ls -1 dbv_*.env | sed 's/dbv_//g' | sed 's/.env//g' | while read db
	# do
	#	echo "<pre>"
	#	${DBV_HOME}/dbvctl -d $db -i
	#	echo "</pre>"
	#	echo "<br>"
	# done
fi