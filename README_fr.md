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

3.  **Rapports de synthèse** : Une page par thème (datafiles, tablespaces, erreurs de l'alert log, sauvegardes RMAN) regroupant toutes les bases sélectionnées, produite par `summary.sh`.
    - Nom du fichier : `Summary_{thème}_{hostname}_{timestamp}.html`

4.  **Graphique RMAN** : Taille et durée des sauvegardes sur les 90 derniers jours pour chaque base sélectionnée, produit par `generate_rman_chart.sh`.
    - Nom du fichier : `RMAN_Chart_{hostname}_{timestamp}.html`

Les rapports sont des fichiers HTML autonomes : aucune police, aucun script ni aucune bibliothèque externe n'est chargé. Ils s'ouvrent hors ligne et peuvent être envoyés tels quels.

## Structure du projet

- `oracle_db_report.sh` : Script principal qui orchestre la génération du rapport serveur et des rapports de base de données.
- `sh/` : Scripts Bash pour la collecte des informations système (utilisés pour le rapport serveur).
- `sql/` : Requêtes SQL pour les données de base de données.
- `html/` : Templates HTML pour l'en-tête et le pied de page des rapports.
- `asm/` : Scripts SQL spécifiques aux instances ASM.
- `summary/` : Scripts SQL utilisés par le script de synthèse.
- `summary.sh` : Script d'agrégation des rapports.
- `rman_chart/` : Template HTML et script SQL du graphique RMAN.
- `generate_rman_chart.sh` : Script de génération du graphique RMAN.

## Personnalisation

- Modifiez `.env` pour changer le répertoire de sortie.
- Ajoutez des scripts dans `sh/` ou `sql/` pour étendre les rapports.

