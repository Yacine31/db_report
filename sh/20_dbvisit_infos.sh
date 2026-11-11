#!/bin/bash

# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# Rapport Dbvisit Standby : statut et gap de chaque configuration (DDC) du serveur.
# Le script ne dépend pas de ORACLE_SID : les configurations sont lues dans
# <DBV_HOME>/conf/dbv_<DDC>.env. Il ne produit rien si Dbvisit n'est pas installé.

# --- Fonctions ---

# Retourne le répertoire qui contient l'exécutable dbvctl, ou rien s'il est introuvable.
# Ordre de recherche :
#   1. la variable DBV_HOME (à définir dans .env pour une installation non standard) ;
#   2. un processus dbvctl lancé avec un chemin absolu (mode démon) ;
#   3. les processus dbvnet / dbvagent / dbvagentmanager, voisins de dbvctl ;
#   4. les emplacements par défaut.
find_dbv_home() {
  local candidate process_path base_dir

  {
    [ -n "${DBV_HOME:-}" ] && echo "${DBV_HOME}"

    ps -eo args | awk '$1 ~ /^\/.*\/dbvctl$/ { print $1 }' | sort -u | while read -r process_path; do
      dirname "${process_path}"
    done

    ps -eo args | awk '$1 ~ /^\/.*\/(dbvnet|dbvagent|dbvagentmanager)$/ { print $1 }' | sort -u | while read -r process_path; do
      # ex. /usr/dbvisit/dbvnet/dbvnet -> /usr/dbvisit
      base_dir="$(dirname "$(dirname "${process_path}")")"
      echo "${base_dir}/standby"
      echo "${base_dir}/oracle"
      echo "${base_dir}/standbymp/oracle"
    done

    echo "/usr/dbvisit/standby"
    echo "/usr/dbvisit/standbymp/oracle"
  } | while read -r candidate; do
    if [ -x "${candidate}/dbvctl" ]; then
      echo "${candidate}"
      break
    fi
  done
}

# Liste les configurations (DDC) : un fichier conf/dbv_<DDC>.env par configuration
list_ddc() {
  local env_file ddc_name
  for env_file in "$1"/conf/dbv_*.env; do
    [ -f "${env_file}" ] || continue
    ddc_name="$(basename "${env_file}" .env)"
    echo "${ddc_name#dbv_}"
  done
}

# --- Script principal ---

DBV_HOME="$(find_dbv_home)"

# Dbvisit absent du serveur : aucune section dans le rapport
[ -n "${DBV_HOME}" ] || exit 0
export DBV_HOME

echo "<h1>Dbvisit Standby Configuration</h1>"

print_h2 "Dbvisit Installation"
echo "<br><pre>DBV_HOME: $(echo "${DBV_HOME}" | html_escape)</pre>"

print_h2 "Running Dbvisit Processes"
run_and_print "ps -ef | grep -E 'dbvctl|dbvnet|dbvagent|dbvserver|dbvcontrol' | grep -v grep"

ddc_list="$(list_ddc "${DBV_HOME}")"

if [ -z "${ddc_list}" ]; then
  print_h2 "Dbvisit Configurations (DDC)"
  echo "<br><pre>No DDC file (dbv_*.env) found in $(echo "${DBV_HOME}/conf" | html_escape).</pre>"
  exit 0
fi

for ddc in ${ddc_list}; do
  print_h2 "Database Status: ${ddc} on $(hostname -s)"
  status_command="'${DBV_HOME}/dbvctl' -d '${ddc}' -o status"
  # Le statut est lu une seule fois : il est affiché, puis sert à savoir si la base est primaire
  status_output="$(eval "${status_command}" 2>&1)"
  echo "<br><pre>"
  echo "<b style=\"color:red;\">$(echo "${status_command}" | html_escape)</b>"
  echo ""
  echo "${status_output}" | html_escape
  echo "</pre>"

  # Le rapport de gap ne s'exécute que depuis la base primaire
  if echo "${status_output}" | grep -qi "read write"; then
    print_h2 "Dbvisit Gap Report for ${ddc}"
    run_and_print "'${DBV_HOME}/dbvctl' -d '${ddc}' -i"
  fi
done
