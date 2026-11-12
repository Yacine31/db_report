#!/bin/bash
# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Script principal ---

print_h2 "Running Databases"
run_and_print "ps -ef | grep pmon | grep -v grep"

print_h2 "Running Listeners"
run_and_print "ps -ef | grep tnslsnr | grep -v grep"

# Statut de chaque listener démarré, quel que soit son nom et son ORACLE_HOME.
# La ligne de commande d'un listener a la forme : <ORACLE_HOME>/bin/tnslsnr <NOM> -inherit
listeners="$(ps -eo args | awk '$1 ~ /\/bin\/tnslsnr$/ && $2 != "" { print $1, $2 }' | sort -u)"

if [ -z "${listeners}" ]; then
  print_h2 "Listener Status"
  echo "<br><pre>No listener is running.</pre>"
else
  while read -r binary_path listener_name; do
    listener_home="${binary_path%/bin/tnslsnr}"
    # le home dans le titre distingue deux listeners de meme nom (ex. grid et base)
    print_h2 "Listener Status: ${listener_name} (${listener_home})"
    # lsnrctl a besoin de l'ORACLE_HOME du listener, qui n'est pas forcément celui du shell courant
    run_and_print "ORACLE_HOME='${listener_home}' TNS_ADMIN='${listener_home}/network/admin' '${listener_home}/bin/lsnrctl' status '${listener_name}'"
  done <<< "${listeners}"
fi

print_h2 "User Limits (ulimit -a)"
run_and_print "ulimit -a | sort"
