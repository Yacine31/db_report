# DB Report

Génère des rapports HTML détaillés sur la configuration d'un serveur et de ses bases de données Oracle.

## Fonctionnalités

- Génération d'un rapport de configuration pour le serveur hôte.
- Collecte automatique des bases de données Oracle en cours d'exécution.
- Génération d'un rapport HTML structuré et détaillé pour chaque base de données.
- Support pour les instances ASM et les PDBs (Pluggable Databases).
- Scripts modulaires pour une personnalisation facile.

## Prérequis

- Système Linux/Unix avec Bash.
- Oracle Database 12c ou supérieur, installé et configuré (avec `sqlplus` et `oraenv`).
- Permissions pour exécuter des requêtes SQL en tant que `sysdba`.

## Installation

```bash
git clone https://github.com/Yacine31/db_report
cd db_report
# Copier le fichier d'exemple de configuration (optionnel)
cp .env.example .env
# Éditer .env si nécessaire (e.g., pour personnaliser OUTPUT_DIR)
```

## Utilisation

```bash
# Toutes les bases en cours d'exécution
bash oracle_db_report.sh

# Une seule base (l'option peut être répétée)
bash oracle_db_report.sh -s ORCL
bash oracle_db_report.sh -s ORCL -s TEST

# Afficher l'aide
bash oracle_db_report.sh -h
```

Le script peut être lancé depuis n'importe quel répertoire.

| Option | Description |
|---|---|
| `-s SID` | Ne traite que cette base. Peut être répétée. La base doit être démarrée, sinon le script s'arrête en listant les bases actives. Par défaut : toutes les bases démarrées. |
| `--vmstat` | Ajoute un échantillon `vmstat 2 20` en direct au rapport serveur (environ 40 secondes). Désactivé par défaut. |
| `-h`, `--help` | Affiche l'aide et quitte. |

Le rapport serveur est toujours généré, quelles que soient les options.

En fin d'exécution, le log liste les erreurs SQL (`ORA-`, `SP2-`, `PLS-`) levées par les scripts du rapport, avec la base et le script concernés, ou `No SQL error detected`.

## Sortie

Le script génère les rapports suivants dans le répertoire `output/YYYYMMDD/` (`{hostname}` est le nom court du serveur) :

1.  **Rapport Serveur** : Un rapport unique contenant les informations de configuration du système d'exploitation (OS, disques, mémoire, activité de swap, homes Oracle et patchs, réseau, paramètres noyau).
    - Nom du fichier : `Rapport_{hostname}_{timestamp}.html`

2.  **Rapports Base de Données** : Un rapport détaillé pour chaque instance de base de données Oracle sélectionnée.
    - Nom du fichier : `Rapport_{hostname}_{SID}_{timestamp}.html`

3.  **Rapports de synthèse** : Une page par thème (synthèse de santé, datafiles, tablespaces, erreurs de l'alert log, sauvegardes RMAN) regroupant toutes les bases sélectionnées, produite par `summary.sh`.
    - Nom du fichier : `Summary_{thème}_{hostname}_{timestamp}.html`

4.  **Graphique RMAN** : Taille et durée des sauvegardes sur les 90 derniers jours pour chaque base sélectionnée, produit par `generate_rman_chart.sh`.
    - Nom du fichier : `RMAN_Chart_{hostname}_{timestamp}.html`

Les rapports sont des fichiers HTML autonomes : aucune police, aucun script ni aucune bibliothèque externe n'est chargé. Ils s'ouvrent hors ligne et peuvent être envoyés tels quels.

## Synthèse de santé

Chaque rapport commence par une synthèse : une ligne par contrôle, avec sa valeur, son seuil et un statut (`OK`, `WARNING`, `CRITICAL` ou `INFO`). Le détail de chaque contrôle se trouve dans la section correspondante, plus bas dans le rapport.

- Contrôles serveur et leurs seuils : en tête de `sh/05_health_summary.sh`.
- Contrôles base : `sql/00a_health_summary.sql` (contrôles possibles sur une base montée) et `sql/00b_health_summary_open.sql` (contrôles qui demandent une base ouverte) ; leurs seuils : `sql/common/health_thresholds.sql`.
- `Summary_health_{hostname}_{timestamp}.html` regroupe sur une page les synthèses de toutes les bases sélectionnées.

## Bases montées (standby)

Sur une base seulement montée (par exemple une standby physique gérée par Dbvisit ou Data Guard), les vues du dictionnaire (`DBA_*`, `CDB_*`) ne sont pas lisibles. Les scripts SQL qui demandent une base ouverte commencent par la ligne `-- db-report: requires-open` : ils sont sautés sur une base montée, et le rapport l'indique en tête de la partie base. Ajouter cette ligne à tout nouveau script qui lit le dictionnaire.

## Rapport Word

`docx_report/db_report_docx.py` génère un rapport Word pré-rempli à partir des rapports HTML. Il s'exécute sur votre poste, pas sur les serveurs, et ne demande que Python 3 (bibliothèque standard).

1. Créer une fois un modèle à partir d'un rapport Word existant. Le corps est coupé à partir du titre indiqué et remplacé par le marqueur `{{CONTENU}}` ; le mois et la date deviennent `{{MOIS}}` et `{{DATE}}` :

```bash
python3 docx_report/db_report_docx.py template rapport_2026-06.docx docx_report/templates/mensuel.docx \
    --content-from "Périmètre" --month "Juin 2026" --date "16/06/2026"
```

2. Copier le répertoire `output/YYYYMMDD` de chaque serveur sur votre poste, puis générer le rapport (un seul document pour plusieurs serveurs) :

```bash
python3 docx_report/db_report_docx.py build -t docx_report/templates/mensuel.docx -o rapport.docx \
    rapports/serveur1 rapports/serveur2
```

Le document est rédigé en français ; les tableaux gardent les libellés anglais des rapports HTML. Il contient le périmètre (serveurs et bases), la liste des contrôles `WARNING` et `CRITICAL`, la synthèse de santé de chaque serveur et de chaque base, les dernières sauvegardes RMAN, les tablespaces au-dessus d'un seuil, le contrôle des exports Data Pump et les dernières erreurs de l'alert log. Les paragraphes « À compléter » sont réservés à votre analyse.

Options de `build` : `--month`, `--date`, `--tbs-min-pct` (70 par défaut), `--health issues|full` (`issues` par défaut : uniquement les contrôles qui ne sont pas OK), `--alert-rows` (10 par défaut).

Les noms des styles utilisés dans le modèle sont listés dans le dictionnaire `STYLES` en tête du script. Les modèles et les documents générés sont ignorés par git (`docx_report/templates/`, `*.docx`) : ils contiennent des données client.

## Structure du projet

- `oracle_db_report.sh` : Script principal qui orchestre la génération du rapport serveur et des rapports de base de données.
- `sh/` : Scripts Bash pour la collecte des informations système (utilisés pour le rapport serveur).
- `sql/` : Requêtes SQL pour les données de base de données.
- `sql/common/` : requêtes communes à une section du rapport de base et à une page de synthèse (non exécutées seules).
- `html/` : Templates HTML pour l'en-tête et le pied de page des rapports.
- `asm/` : Scripts SQL spécifiques aux instances ASM.
- `summary/` : Scripts SQL utilisés par le script de synthèse.
- `summary.sh` : Script d'agrégation des rapports.
- `rman_chart/` : Template HTML et script SQL du graphique RMAN.
- `generate_rman_chart.sh` : Script de génération du graphique RMAN.
- `docx_report/` : générateur du rapport Word, à lancer sur le poste de travail (les modèles ne sont pas versionnés).

## Personnalisation

- Modifiez `.env` pour changer le répertoire de sortie.
- Ajoutez des scripts dans `sh/` ou `sql/` pour étendre les rapports.

