#!/bin/bash
# Script de génération de rapports HTML pour les bases de données Oracle.
# Collecte des informations système, ASM, PDBs et configurations via scripts Bash/SQL.

# Stoppe le script en cas d'erreur (erreurs, variables non définies, pipes échoués)
set -euo pipefail

source sh/utils.sh

# --- Configuration initiale ---
# Définit les variables globales et charge la configuration utilisateur.
# Définit la langue pour les commandes (évite les problèmes de locale)
export LANG=en_US
# Génère un timestamp pour nommer les fichiers
timestamp="$(date +%Y%m%d%H%M)"
# Récupère le nom d'hôte du serveur
hostname="$(hostname)"

# Charge la configuration depuis .env si le fichier existe
if [ -f .env ]; then
  # shellcheck source=.env
  source .env
fi

# Définit le répertoire de sortie (peut être surchargé par la variable OUTPUT_DIR dans .env)
output_dir_base="${OUTPUT_DIR:-"output"}"
output_dir="${output_dir_base}/$(date +%Y%m%d)"

# --- Définitions des fonctions ---
# Contient les fonctions utilitaires pour logging et exécution de scripts.

# Fonction: execute_scripts
# Description: Exécute une série de scripts (Bash ou SQL) et ajoute leur sortie au rapport HTML.
#               Vérifie d'abord si des scripts correspondent au pattern.
# Paramètres:
#   $1 (section_title) - Titre de la section dans le rapport HTML.
#   $2 (script_pattern) - Chemin vers les scripts (e.g., "sh/*.sh").
#   $3 (script_type) - Type de script : "sh" pour Bash, "sql" pour SQL.
#   $4 (sql_header_file) - Fichier d'en-tête SQL (optionnel, utilisé seulement pour "sql").
#   Exemple : execute_scripts "Configuration système" "sh/*.sh" "sh"
execute_scripts() {
  local section_title="$1"
  local script_pattern="$2"
  local script_type="$3"
  local sql_header_file="${4:-}"

  # Vérifie s'il y a des fichiers correspondants au pattern pour éviter les erreurs
  # Utilise ls au lieu de find pour compatibilité, avec shellcheck désactivé pour SC2012
  # shellcheck disable=SC2012
  # if [ -z "$(ls -1 "${script_pattern}" 2>/dev/null)" ]; then
  #   log_info "Aucun script trouvé pour le pattern '${script_pattern}', section ignorée."
  #   return
  # fi

  echo "<h1>"${section_title}"</h1>" >> "${html_report_file}"
  # Boucle sur chaque script correspondant au pattern
  for script_file in ${script_pattern}; do
    log_info "Exécution du script : ${script_file}"
    case "${script_type}" in
      sh)
        # Exécute le script Bash et ajoute sa sortie au rapport
        bash "${script_file}" >> "${html_report_file}"
        ;;
      sql)
        # Concatène l'en-tête SQL avec le script et l'exécute via sqlplus
        cat "${sql_header_file}" "${script_file}" | sqlplus -s / as sysdba >> "${html_report_file}"
        ;;
    esac
  done
  echo "<br><br>" >> "${html_report_file}"
  echo "<p><a href=\"#top\">Retour en haut de page</a></p>" >> "${html_report_file}"
} # execute_scripts


# --- Script principal ---
# Orchestre la génération des rapports pour chaque base de données détectée.

# Crée le répertoire de sortie si nécessaire
mkdir -p "${output_dir}"

#--------------- LES SERVEURS
log_info "Début de la génération des rapports pour le serveur : "${hostname}""

# Définit le nom du fichier HTML du rapport
html_report_file="${output_dir}/Rapport_"${hostname}"_"${timestamp}".html"

# Copie l'en-tête HTML et ajoute l'ancre pour le lien "retour en haut"
cat html/00_html_header.html > "${html_report_file}"
echo '<div id="top"></div>' >> "${html_report_file}"

# Génère la date formatée pour l'affichage dans le rapport
current_date="$(date +"%d/%m/%Y %Hh%M")"
{
  echo "<h1>Rapport de configuration du serveur "${hostname}"</h1>"
  echo "<h2>Date : "${current_date}"</h2>"
  echo "<h2>Hostname : "${hostname}"</h2>"
  echo "<br><br>"
 } >> "${html_report_file}"

# Exécute les scripts de collecte d'informations via la fonction execute_scripts
execute_scripts "Configuration système" "sh/*.sh" "sh"

# Ajoute le pied de page HTML au rapport
cat html/99_html_footer.html >> "${html_report_file}"
log_info "Rapport généré : "${html_report_file}""
#--------------- 

#--------------- LES BASES
# Détecte les bases de données Oracle en cours d'exécution
# Exclut les instances ASM et APX pour se concentrer sur les bases utilisateur
database_sids="$(ps -eaf | grep pmon | egrep -v 'grep|ASM|APX1' | cut -d '_' -f3 || true)"

if [ -z "${database_sids}" ]; then
  echo "[WARN] Aucune base de données Oracle détectée. Fin du script."
  exit 0
fi


log_info "Début de la génération des rapports pour les bases : "${database_sids}""

for database_sid in ${database_sids}; do
  # Désactive les prompts d'oraenv et définit la base courante
  export ORAENV_ASK=NO
  export ORACLE_SID="${database_sid}"
  
  log_info "Traitement de la base de données : "${ORACLE_SID}""
  # Configure l'environnement Oracle pour la base actuelle
  # shellcheck source=/dev/null
  . oraenv -s > /dev/null

  # Définit le nom du fichier HTML du rapport
  html_report_file="${output_dir}/Rapport_"${hostname}"_"${ORACLE_SID}"_"${timestamp}".html"
  
   # --- Génération du rapport HTML pour cette base ---
   # Initialise le fichier HTML avec l'en-tête et les infos générales.

   # Copie l'en-tête HTML et ajoute l'ancre pour le lien "retour en haut"
   cat html/00_html_header.html > "${html_report_file}"
   echo '<div id="top"></div>' >> "${html_report_file}"
  
  # Génère la date formatée pour l'affichage dans le rapport
  current_date="$(date +"%d/%m/%Y %Hh%M")"
  {
    echo "<h1>Rapport de base de données "${ORACLE_SID}" sur le serveur "${hostname}"</h1>"
    echo "<h2>Date : "${current_date}"</h2>"
    echo "<h2>Hostname : "${hostname}"</h2>"
    echo "<h2>Base de données : "${ORACLE_SID}"</h2>"
    echo "<br><br>"
   } >> "${html_report_file}"

  #  # Exécute les scripts de collecte d'informations via la fonction execute_scripts
  # execute_scripts "Configuration système" "sh/*.sh" "sh"

  # Si une instance ASM est détectée, exécute les scripts ASM
  if [ "$(ps -ef | grep pmon | grep ASM | wc -l)" -gt 0 ]; then
    execute_scripts "Configuration de l'instance ASM" "asm/*.sql" "sql" "sql/sql_header.txt"
  fi

  # Si la base est un CDB (Container Database), exécute les scripts pour les PDBs
  if [ "$(/bin/sh sql/cdb/is_CDB.sh | tail -1)" = "YES" ]; then
    execute_scripts "Informations sur les PDBs" "sql/cdb/*.sql" "sql" "sql/sql_header.txt"
  fi

  execute_scripts "Configuration de la base de données "${ORACLE_SID}"" "sql/*.sql" "sql" "sql/sql_header.txt"

  # Ajoute le pied de page HTML au rapport
  cat html/99_html_footer.html >> "${html_report_file}"

  log_info "Rapport généré : "${html_report_file}""
  done
#--------------- 

# Une fois tous les rapports générés, exécute le script de synthèse pour agréger les données
log_info "Exécution du script de synthèse."
export OUTPUT_DIR="${output_dir}"
export DATETIME="${timestamp}"
export HNAME="${hostname}"
bash summary.sh

log_info "Fin du script."