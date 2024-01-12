# script à exécuter si seulement dbvctl existe et une instance avec le nom de service dbv existe aussi

count=$(ps -ef | grep dbvctl | grep -v grep | grep ${ORACLE_SID} | wc -l)

if [ $count -gt 0 ]; then

	echo "<h1>Configuration DBVisit</h1>"
	# les process dbvisit en cours 
	echo "<h2>Process DBVisit en cours d'exécution</h2>"
	echo "<pre>"
	ps -ef | grep dbvctl | grep -v grep 
	echo "</pre>"

	# on récupère le chemin de l'executable dbvctl
	export DBV_HOME=$(dirname $(ps -ef | grep dbvctl | grep -v grep | awk '{print $8}' | sort -u))
	# si les exacutables sont lancé avec ./dbvctl, le résultat retourné est .
	# dans ce cas on remplace par la valeur par défaut : /usr/dbvisit/standby
	if [ "$DBV_HOME" = "." ]; then
		# Attribuer une nouvelle valeur à DBV_HOME
		export DBV_HOME="/usr/dbvisit/standby"
	fi

	# statut de la base de données
	echo "<h2>Statut de la base : ${ORACLE_SID} sur le serveur $(hostname)</h2>"
	echo "<pre>"
	${DBV_HOME}/dbvctl -d ${ORACLE_SID} -o status
	echo "</pre>"

	# on récupère le statut de la base pour exécuter la commande sur la base primaire
	db_prim=$(${DBV_HOME}/dbvctl -d ${ORACLE_SID} -o status | grep -i "read write" | wc -l)
	if [ ${db_prim} -gt 0 ]; then
		echo "<h2>Rapport de GAP DBVisit pour la base ${ORACLE_SID}</h2>"
		echo "<pre>"
		${DBV_HOME}/dbvctl -d ${ORACLE_SID} -i
		echo "</pre>"
	fi
fi