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
- Oracle Database installé et configuré (avec `sqlplus` et `oraenv`).
- Permissions pour exécuter des requêtes SQL en tant que `sysdba`.

## Installation

```bash
git clone https://github.com/Yacine31/db_report
cd db_report
# Copier le fichier d'exemple de configuration (optionnel)
cp .env.local .env
# Éditer .env si nécessaire (e.g., pour personnaliser OUTPUT_DIR)
```

## Utilisation

```bash
# Exécuter le script principal
bash rapport_bdd.sh
```

## Sortie

Le script génère deux types de rapports dans le répertoire `output/YYYYMMDD/`:

1.  **Rapport Serveur** : Un rapport unique contenant les informations de configuration du système d'exploitation.
    - Nom du fichier : `Rapport_{hostname}_{timestamp}.html`

2.  **Rapports Base de Données** : Un rapport détaillé pour chaque instance de base de données Oracle détectée.
    - Nom du fichier : `Rapport_{hostname}_{SID}_{timestamp}.html`

Un script de synthèse (`summary.sh`) est également exécuté pour agréger certaines données des différentes bases.

## Structure du projet

- `rapport_bdd.sh` : Script principal qui orchestre la génération du rapport serveur et des rapports de base de données.
- `sh/` : Scripts Bash pour la collecte des informations système (utilisés pour le rapport serveur).
- `sql/` : Requêtes SQL pour les données de base de données.
- `html/` : Templates HTML pour l'en-tête et le pied de page des rapports.
- `asm/` : Scripts SQL spécifiques aux instances ASM.
- `summary/` : Scripts SQL utilisés par le script de synthèse.
- `summary.sh` : Script d'agrégation des rapports.

## Personnalisation

- Modifiez `.env` pour changer le répertoire de sortie.
- Ajoutez des scripts dans `sh/` ou `sql/` pour étendre les rapports.

