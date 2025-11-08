# DB Report

Génère des rapports HTML détaillés sur les bases de données Oracle, incluant les informations système, configurations, fichiers, logs et sauvegardes.

## Fonctionnalités

- Collecte automatique des bases de données Oracle en cours d'exécution.
- Génération de rapports HTML structurés avec navigation.
- Support pour les instances ASM et les PDBs (Pluggable Databases).
- Scripts modulaires pour une personnalisation facile.

## Prérequis

- Système Linux/Unix avec Bash.
- Oracle Database installé et configuré (avec `sqlplus` et `oraenv`).
- Permissions pour exécuter des requêtes SQL en tant que `sysdba`.

## Installation

```bash
git clone https://github.com/Yacine31/db_report
cd db_report
# Copier le fichier d'exemple de configuration
cp .env.local .env
# Éditer .env si nécessaire (e.g., pour personnaliser OUTPUT_DIR)
```

## Utilisation

```bash
# Exécuter le script principal
bash rapport_bdd.sh
```

Le script détecte automatiquement les bases de données Oracle actives et génère un rapport HTML pour chacune.

## Sortie

Les rapports sont sauvegardés dans le répertoire `output/YYYYMMDD/`, avec un fichier par base (e.g., `Rapport_hostname_SID_timestamp.html`).

Un script de synthèse (`summary.sh`) peut être exécuté pour agréger les données.

## Structure du projet

- `rapport_bdd.sh` : Script principal.
- `sh/` : Scripts Bash pour la collecte d'infos système.
- `sql/` : Requêtes SQL pour les données de base.
- `html/` : Templates HTML pour le rapport.
- `asm/` : Scripts spécifiques aux instances ASM.
- `summary.sh` : Script d'agrégation des rapports.

## Personnalisation

- Modifiez `.env` pour changer le répertoire de sortie.
- Ajoutez des scripts dans `sh/` ou `sql/` pour étendre les rapports.
- Consultez `AGENTS.md` pour les commandes de build/lint/test.

## Licence

[Ajoutez votre licence ici, e.g., MIT]
