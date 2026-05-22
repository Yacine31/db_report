#!/bin/bash
# Lance analyze_report.py dans le virtualenv

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_PYTHON="${SCRIPT_DIR}/venv/bin/python3"

if [ ! -f "${VENV_PYTHON}" ]; then
    echo "Erreur : virtualenv non trouvé. Lance d'abord : bash ai_analysis/setup.sh"
    exit 1
fi

"${VENV_PYTHON}" "${SCRIPT_DIR}/analyze_report.py" "$@"
