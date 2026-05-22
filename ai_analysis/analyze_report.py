#!/usr/bin/env python3
"""
analyze_report.py — Analyse IA des rapports db_report via Ollama.

Usage:
    python3 analyze_report.py /path/to/Rapport_xxx.html

Pour chaque section <h2> du rapport, envoie le contenu à Ollama et insère
un bloc d'analyse sous la section si le LLM détecte quelque chose de notable.
"""

import sys
import os
import re
import json
import requests
from pathlib import Path
from bs4 import BeautifulSoup, NavigableString, Tag

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).parent

def load_env():
    env = {"OLLAMA_URL": "http://localhost:11434", "OLLAMA_MODEL": "llama3"}
    env_file = SCRIPT_DIR / ".env"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, _, value = line.partition("=")
                env[key.strip()] = value.strip()
    for key in env:
        if key in os.environ:
            env[key] = os.environ[key]
    return env

# ---------------------------------------------------------------------------
# CSS injecté dans le rapport
# ---------------------------------------------------------------------------

AI_CSS = """
.ai-analysis {
    background: #eef6ff;
    border-left: 4px solid #2563eb;
    border-radius: 4px;
    padding: 10px 16px;
    margin: 4px 0 16px 0;
    font-size: 0.92em;
    color: #1e3a5f;
}
.ai-analysis-title {
    font-weight: bold;
    color: #1d4ed8;
    margin-bottom: 4px;
}
"""

# ---------------------------------------------------------------------------
# Ollama
# ---------------------------------------------------------------------------

PROMPT_TEMPLATE = """Tu es un assistant DBA Oracle. Analyse cette section d'un rapport de configuration de base de données.

Titre de la section : {title}

Contenu :
{content}

Si tu détectes un problème, un risque ou une recommandation utile pour un DBA, réponds en français en 2 à 4 phrases concises et précises.
S'il n'y a rien de notable, réponds uniquement : NO_REMARK"""


def query_ollama(title, content, ollama_url, model):
    prompt = PROMPT_TEMPLATE.format(title=title, content=content[:4000])
    payload = {"model": model, "prompt": prompt, "stream": False}
    response = requests.post(
        f"{ollama_url}/api/generate",
        json=payload,
        timeout=120,
    )
    response.raise_for_status()
    return response.json().get("response", "").strip()


# ---------------------------------------------------------------------------
# Extraction du texte d'une section
# ---------------------------------------------------------------------------

def extract_text(elements):
    lines = []
    for el in elements:
        if isinstance(el, NavigableString):
            text = el.strip()
            if text:
                lines.append(text)
        elif isinstance(el, Tag):
            if el.name == "table":
                lines.append(table_to_text(el))
            elif el.name == "pre":
                lines.append(el.get_text())
            else:
                text = el.get_text(" ", strip=True)
                if text:
                    lines.append(text)
    return "\n".join(lines).strip()


def table_to_text(table):
    rows = []
    for tr in table.find_all("tr"):
        cells = [td.get_text(" ", strip=True) for td in tr.find_all(["th", "td"])]
        rows.append(" | ".join(cells))
    return "\n".join(rows)


# ---------------------------------------------------------------------------
# Script principal
# ---------------------------------------------------------------------------

def build_ai_block(remark):
    return BeautifulSoup(
        f'<div class="ai-analysis">'
        f'<div class="ai-analysis-title">&#129302; Analyse IA</div>'
        f'<div>{remark}</div>'
        f'</div>',
        "html.parser",
    )


def analyze(html_path, ollama_url, model):
    html = Path(html_path).read_text(encoding="utf-8", errors="replace")
    soup = BeautifulSoup(html, "html.parser")

    # Injecter le CSS
    style_tag = soup.find("style")
    if style_tag:
        style_tag.append(NavigableString(AI_CSS))

    h2_tags = soup.find_all("h2")
    if not h2_tags:
        print("Aucune section <h2> trouvée dans le rapport.")
        return

    total = len(h2_tags)
    for idx, h2 in enumerate(h2_tags):
        title = h2.get_text(strip=True)
        print(f"[{idx+1}/{total}] Analyse : {title}", flush=True)

        # Collecter les éléments entre ce h2 et le suivant
        siblings = []
        for sibling in h2.next_siblings:
            if isinstance(sibling, Tag) and sibling.name == "h2":
                break
            siblings.append(sibling)

        content = extract_text(siblings)
        if len(content) < 20:
            print(f"  → Section trop courte, ignorée.")
            continue

        try:
            remark = query_ollama(title, content, ollama_url, model)
        except requests.exceptions.ConnectionError:
            print(f"\nErreur : impossible de joindre Ollama sur {ollama_url}.")
            print("Vérifiez qu'Ollama est démarré et que l'URL est correcte dans ai_analysis/.env")
            sys.exit(1)
        except requests.exceptions.RequestException as e:
            print(f"  → Erreur Ollama : {e}")
            continue

        if remark.strip().upper() == "NO_REMARK" or not remark.strip():
            print(f"  → Rien de notable.")
            continue

        print(f"  → Remarque insérée.")
        # Insérer le bloc après le dernier élément de la section
        last = siblings[-1] if siblings else h2
        last.insert_after(build_ai_block(remark))

    Path(html_path).write_text(str(soup), encoding="utf-8")
    print(f"\nRapport mis à jour : {html_path}")


def main():
    if len(sys.argv) != 2:
        print(f"Usage: python3 {sys.argv[0]} /path/to/rapport.html")
        sys.exit(1)

    html_path = sys.argv[1]
    if not Path(html_path).exists():
        print(f"Erreur : fichier introuvable : {html_path}")
        sys.exit(1)

    env = load_env()
    ollama_url = env["OLLAMA_URL"].rstrip("/")
    model = env["OLLAMA_MODEL"]

    print(f"Ollama : {ollama_url}  |  Modèle : {model}")
    print(f"Rapport : {html_path}\n")

    analyze(html_path, ollama_url, model)


if __name__ == "__main__":
    main()
