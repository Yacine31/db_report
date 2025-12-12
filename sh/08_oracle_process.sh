#!/bin/bash
# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Script principal ---

print_h2 "Bases de données en cours d'exécution"
run_and_print "ps -ef | grep pmon | grep -v grep"

print_h2 "Listeners en cours d'exécution"
run_and_print "ps -ef | grep tnslsnr | grep -v grep"

print_h2 "Statut du listener : ${listener_name}"
# Boucle pour le statut du listener, car elle est plus complexe
ps -ef | grep tnslsnr | egrep -i " LISTENER |${ORACLE_SID}" | grep -v grep | while read -r l; do
  binary_path=$(echo "$l" | perl -lne 'print $1 if /(\S*tnslsnr\S*)/' | sed 's#/bin/tnslsnr##')
  listener_name=$(echo "$l" | perl -lne 'print $1 if /\btnslsnr\s+(\S+)/' | sed 's/tnslsnr //')
  
  if [ -n "$binary_path" ] && [ -n "$listener_name" ]; then
    export TNS_ADMIN="$binary_path/network/admin"
    lsnrctl_command="$binary_path/bin/lsnrctl status $listener_name"
    # echo "<b>Listener: ${listener_name}</b>"
    run_and_print "$lsnrctl_command"
  fi
done

print_h2 "Limites de l'utilisateur (ulimit -a)"
run_and_print "ulimit -a | sort"



