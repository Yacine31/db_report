# script à exécuter si seulement dbvctl existe et une instance avec le nom de service dbv existe aussi

count=$(ps -ef | grep dbvctl | grep -v grep | grep ${ORACLE_SID} | wc -l)

if [ $count -gt 0 ]; then
	# dbvisit
	echo "<h2>Process DBVisit</h2>"
	echo "<pre>"
	ps -ef | grep dbvctl | grep -v grep 
	echo "</pre>"

	echo "<h2>dbvctl gap report</h2>"
	export DBV_HOME=$(dirname $(ps -ef | grep dbvctl | grep -v grep | awk '{print $8}' | sort -u))

	echo "<pre>"
	${DBV_HOME}/dbvctl -d ${ORACLE_SID} -i
	echo "</pre>"
fi