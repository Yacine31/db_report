#!/bin/bash

# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Script principal ---

# script à exécuter si seulement dbvctl existe et une instance avec le nom de service dbv existe aussi

count=$(ps -ef | grep dbvctl | grep -v grep | grep "${ORACLE_SID}" | wc -l)

if [ "$count" -gt 0 ]; then

	echo "<h1>Configuration DBVisit</h1>"
	print_h2 "Process DBVisit en cours d'exécution"
	run_and_print "ps -ef | grep dbvctl | grep -v grep"

	# on récupère le chemin de l'executable dbvctl
	export DBV_HOME=$(dirname "$(ps -ef | grep dbvctl | grep -v grep | awk '{print $8}' | sort -u)")
	# si les exacutables sont lancé avec ./dbvctl, le résultat retourné est .
	# dans ce cas on remplace par la valeur par défaut : /usr/dbvisit/standby
	if [ "$DBV_HOME" = "." ]; then
		# Attribuer une nouvelle valeur à DBV_HOME
		export DBV_HOME="/usr/dbvisit/standby"
	fi

	print_h2 "Statut de la base : ${ORACLE_SID} sur le serveur $(hostname)"
	run_and_print "${DBV_HOME}/dbvctl -d ${ORACLE_SID} -o status"

	# on récupère le statut de la base pour exécuter la commande sur la base primaire
	db_prim=$("${DBV_HOME}/dbvctl" -d "${ORACLE_SID}" -o status | grep -i "read write" | wc -l)
	if [ "${db_prim}" -gt 0 ]; then
		print_h2 "Rapport de GAP DBVisit pour la base ${ORACLE_SID}"
		run_and_print "${DBV_HOME}/dbvctl -d ${ORACLE_SID} -i"
	fi
fi