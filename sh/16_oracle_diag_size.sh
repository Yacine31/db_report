#!/bin/bash
# Taille des repertoires de diagnostic (ADR) et d'audit (adump) de chaque base demarree
source "$(dirname "$0")/utils.sh"

for sid in $(list_db_sids); do
  set_oracle_env "$sid"
  adr_home=$(sql_value "select value from v\$diag_info where name = 'ADR Home';")
  audit_dest=$(sql_value "select value from v\$parameter where name = 'audit_file_dest';")

  print_h2 "Diagnostic and Audit Files Size: ${sid}"

  if [ -n "$adr_home" ] && [ -d "$adr_home" ]; then
    run_and_print "du -sh ${adr_home}/* 2>/dev/null | sort -rh | head -10"
    run_and_print "ls -lh ${adr_home}/trace/alert_${sid}.log"
  else
    echo "<pre>ADR home not found for ${sid}.</pre>"
  fi

  if [ -n "$audit_dest" ] && [ -d "$audit_dest" ]; then
    # Taille du repertoire d'audit, puis nombre de fichiers qu'il contient
    run_and_print "du -sh ${audit_dest} && find ${audit_dest} -maxdepth 1 -type f | wc -l"
  else
    echo "<pre>Audit file destination not found for ${sid}.</pre>"
  fi
done
