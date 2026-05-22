#!/bin/bash
# Crée un virtualenv et installe les dépendances Python pour analyze_report.py

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/venv"

echo "Création du virtualenv dans ${VENV_DIR}..."
python3 -m venv "${VENV_DIR}"

echo "Installation des dépendances..."
"${VENV_DIR}/bin/pip" install --quiet requests beautifulsoup4

echo ""
echo "Installation terminée. Pour analyser un rapport :"
echo "  ${SCRIPT_DIR}/run.sh /path/to/Rapport_xxx.html"
