#!/bin/bash

# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Script principal ---

print_h2 "Content of /etc/oratab"
run_and_print "cat /etc/oratab | egrep -v '^$|^#'"

print_h2 "Content of Inventory.xml"
# On s'assure que le fichier oraInst.loc existe et est lisible
if [ -r /etc/oraInst.loc ]; then
  ORA_INVENTORY=$(grep inventory_loc /etc/oraInst.loc | cut -d= -f2)
  if [ -n "${ORA_INVENTORY}" ] && [ -r "${ORA_INVENTORY}/ContentsXML/inventory.xml" ]; then
    run_and_print "grep '<HOME NAME=' ${ORA_INVENTORY}/ContentsXML/inventory.xml | awk '{print \$2 \" \" \$3}'"
  else
    echo "<pre>Unable to read inventory.xml, or path not found.</pre>"
  fi
else
  echo "<pre>File /etc/oraInst.loc not found.</pre>"
fi

print_h2 "ORACLE_HOME Patch Level (opatch lspatches)"
if [ -r "${ORA_INVENTORY}/ContentsXML/inventory.xml" ]; then
  # Utilise un `while read` pour plus de robustesse que `cat ... | while`
  while read -r line; do
    # Ignore les lignes vides ou commentées
    [[ "$line" =~ ^# ]] || [ -z "$line" ] && continue

    oh=$(echo "$line" | cut -d: -f2 | sort -u)
    if [ -x "$oh/OPatch/opatch" ]; then
      export ORACLE_HOME=$oh
      run_and_print "\"$oh/OPatch/opatch\" lspatches"
    elif [ -d "$oh" ]; then
      # Home present dans l'inventaire mais sans OPatch (ex. homes OMS clones)
      echo "<pre>${oh} : OPatch absent, patch level non disponible.</pre>"
    fi
  done < <(grep -oP 'LOC="\K[^"]+' ${ORA_INVENTORY}/ContentsXML/inventory.xml)
else
    echo "<pre>File ${ORA_INVENTORY}/ContentsXML/inventory.xml not found.</pre>"
fi

