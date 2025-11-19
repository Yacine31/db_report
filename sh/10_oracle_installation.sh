#!/bin/bash

# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Script principal ---

print_h2 "Contenu du fichier /etc/oratab"
run_and_print "cat /etc/oratab | egrep -v '^$|^#'"

print_h2 "Contenu du fichier Inventory.xml"
# On s'assure que le fichier oraInst.loc existe et est lisible
if [ -r /etc/oraInst.loc ]; then
  ORA_INVENTORY=$(grep inventory_loc /etc/oraInst.loc | cut -d= -f2)
  if [ -n "${ORA_INVENTORY}" ] && [ -r "${ORA_INVENTORY}/ContentsXML/inventory.xml" ]; then
    run_and_print "grep '<HOME NAME=' ${ORA_INVENTORY}/ContentsXML/inventory.xml | awk '{print \$2 \" \" \$3}'"
  else
    echo "<pre>Impossible de lire le fichier inventory.xml ou chemin non trouvé.</pre>"
  fi
else
  echo "<pre>Fichier /etc/oraInst.loc non trouvé.</pre>"
fi

print_h2 "Niveau de patch des ORACLE_HOME (opatch lspatches)"
if [ -r "${ORA_INVENTORY}/ContentsXML/inventory.xml" ]; then
  # Utilise un `while read` pour plus de robustesse que `cat ... | while`
  while read -r line; do
    # Ignore les lignes vides ou commentées
    [[ "$line" =~ ^# ]] || [ -z "$line" ] && continue

    oh=$(echo "$line" | cut -d: -f2 | sort -u)
    if [ -d "$oh" ]; then
      export ORACLE_HOME=$oh
      run_and_print "\"$oh/OPatch/opatch\" lspatches"
    fi
  done < <(grep -oP 'LOC="\K[^"]+' ${ORA_INVENTORY}/ContentsXML/inventory.xml)
else
    echo "<pre>Fichier ${ORA_INVENTORY}/ContentsXML/inventory.xml non trouvé.</pre>"
fi

print_h2 "Bases de données en cours d'exécution"
run_and_print "ps -ef | grep pmon | grep -v grep"

print_h2 "Listeners en cours d'exécution"
run_and_print "ps -ef | grep tnslsnr | grep -v grep"

# Boucle pour le statut du listener, car elle est plus complexe
# ps -ef | grep tnslsnr | egrep -i " LISTENER |${ORACLE_SID}" | grep -v grep | while read -r l; do
# On parcours tous les listener qui tournent sur le serveur pour afficher leur statut
ps -ef | grep tnslsnr | grep -v grep | while read -r l; do
  binary_path=$(echo "$l" | perl -lne 'print $1 if /(\S*tnslsnr\S*)/' | sed 's#/bin/tnslsnr##')
  listener_name=$(echo "$l" | perl -lne 'print $1 if /\btnslsnr\s+(\S+)/' | sed 's/tnslsnr //')
  
  if [ -n "$binary_path" ] && [ -n "$listener_name" ]; then
    export TNS_ADMIN="$binary_path/network/admin"
    print_h2 "Statut du listener : ${listener_name}"
    lsnrctl_command="$binary_path/bin/lsnrctl status $listener_name"
    run_and_print "$lsnrctl_command"
  fi
done
