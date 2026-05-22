#!/bin/bash

# Fichier de fonctions utilitaires pour les scripts de rapport

# Fonction: log_info
# Description: Affiche un message d'information dans les logs avec un timestamp.
# Paramètres:
#   $1 - Le message à afficher.
log_info() {
  echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - ${1}"
}

# Affiche un titre H3
print_h3() {
  echo "<h3>$1</h3>"
}

# Affiche un titre H2
print_h2() {
  echo "<h2>$1</h2>"
}

# Affiche un titre H1
print_h1() {
  echo "<h1>$1</h1>"
}

html_escape() {
  sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

# Exécute une commande et affiche sa sortie dans une balise <pre>
# Si la commande échoue, elle affiche un message d'erreur mis en évidence.
run_and_print() {
  local cmd="$1"
  local cmd_html
  local output

  cmd_html=$(echo "${cmd}" | html_escape)

  echo "<br><pre>"
  echo "<b style=\"color:red;\">${cmd_html}</b>"
  echo ""

  if output=$(eval "${cmd}" 2>&1); then
    echo "$output" | html_escape
  else
    echo "<div class=\"error-block\">"
    echo "ERREUR: La commande a échoué avec le message suivant :"
    echo "$output" | html_escape
    echo "</div>"
  fi
  echo "</pre>"
}
