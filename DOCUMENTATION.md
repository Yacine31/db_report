# Documentation du Projet DB Report

## Introduction

Ce document fournit une description détaillée du projet `db_report`, de sa structure, de ses scripts et de la manière de le personnaliser.

## Structure des Rapports

Le projet génère deux types de rapports HTML :

1.  **Rapport Serveur** : Un rapport unique (`Rapport_{hostname}_{timestamp}.html`) qui contient des informations sur la configuration du système d'exploitation hôte. Ces informations sont collectées par les scripts situés dans le répertoire `sh/`.

2.  **Rapports de Base de Données** : Un rapport détaillé (`Rapport_{hostname}_{SID}_{timestamp}.html`) pour chaque instance de base de données Oracle détectée sur le serveur. Ces rapports contiennent des informations spécifiques à la base de données, collectées par les scripts des répertoires `sql/`, `asm/` et `sql/cdb/`.

## Description des Scripts

### Scripts Principaux

| Script | Description |
| :--- | :--- |
| `rapport_bdd.sh` | Script principal qui orchestre la génération du rapport serveur, puis des rapports pour chaque base de données. |
| `summary.sh` | Exécuté à la fin, ce script génère des rapports de synthèse qui agrègent des informations spécifiques (ex: datafiles, erreurs) de toutes les bases de données. |

### Scripts Shell (`sh/`)

Ces scripts collectent des informations sur le système d'exploitation.

| Script | Description |
| :--- | :--- |
| `09_os_info.sh` | Collecte un ensemble complet d'informations système : uptime, `fstab`, `crontab`, limites `ulimit`, utilisation des disques (`df`, `lsblk`), mémoire (`free`), CPU (`lscpu`), statistiques de performance (`vmstat`, `top`), et les derniers messages du noyau (`dmesg`). |
| `10_oracle_installation.sh` | Liste les Oracle Homes installés en lisant l'inventaire Oracle. |
| `20_dbvisit_infos.sh` | Collecte des informations sur la configuration de Dbvisit Standby, si présent. |
| `30_crs.sh` | Collecte des informations sur les services de cluster Oracle (CRS), si applicable. |
| `utils.sh` | Contient des fonctions utilitaires partagées par les autres scripts shell. |

### Scripts SQL (`sql/`)

Ces scripts collectent des informations détaillées sur la configuration et l'état de chaque base de données.

| Script | Description |
| :--- | :--- |
| `01_system_info.sql` | Informations générales sur la base (version, taille, configuration mémoire, etc.). |
| `11_get_db_size.sql` | Taille détaillée de la base de données (data, temp, log, control files). |
| `12a_instance_status.sql` | Statut de l'instance et de la base de données (rôle, mode d'ouverture, etc.). |
| `12c_db_version.sql` | Composants et versions installés dans la base. |
| `13_database_parameters.sql` | Paramètres de la base de données qui ne sont pas à leur valeur par défaut. |
| `14_nls_database_parameters.sql` | Paramètres de langue (NLS) de la base. |
| `15_check_supplemntal_logging.sql` | Statut du logging supplémentaire. |
| `16_dba_registry.sql` | Composants enregistrés dans `DBA_REGISTRY`. |
| `17_resource_limits.sql` | Limites des ressources pour les processus et sessions. |
| `18_memory_configuration.sql` | Configuration détaillée de la mémoire (SGA, PGA). |
| `19a_memory_resize_operations.sql` | 50 dernières opérations de redimensionnement de la mémoire. |
| `19b_memory_target_advice.sql` | Recommandations de la base pour les cibles mémoire (SGA, PGA, Memory Target). |
| `20a_tbs_details.sql` | Détail de l'utilisation de chaque tablespace. |
| `20c_datafile.sql` | Détail de l'utilisation de chaque datafile. |
| `20d_tempfile.sql` | Détail des fichiers temporaires (tempfiles). |
| `20e_undo.sql` | Détail du tablespace UNDO. |
| `21c_block_corruption.sql` | Blocs corrompus détectés dans la base. |
| `22a_online_log.sql` | Fichiers de journalisation en ligne (redo logs). |
| `22b_online_log.sql` | Multiplexage des fichiers de journalisation. |
| `23a_archive_log_per_day.sql` | Historique du nombre de changements de log par jour. |
| `23b_archive_log_per_day.sql` | Taille des archives générées par jour. |
| `24a_fra_usage.sql` | Utilisation de la Fast Recovery Area (FRA). |
| `24b_fra_usage.sql` | Détail des occupants de la FRA. |
| `25_last_alertlog_errors.sql` | 50 dernières erreurs ORA- dans l'alert log. |
| `26_rman_configuration.sql` | Configuration RMAN. |
| `27_last_rman_backup.sql` | 50 dernières sauvegardes RMAN. |
| `28_sysaux_occupants.sql` | Occupants du tablespace SYSAUX. |
| `30a_users.sql` | Liste des utilisateurs de la base. |
| `30b_users.sql` | Profils de la base de données. |
| `30c_schema_size.sql` | Taille de chaque schéma (en Mo). |
| `31a_who_is_connected.sql` | Sessions agrégées par utilisateur et type. |
| `31b_who_is_connected.sql` | Sessions agrégées par module et action. |
| `31c_who_is_connected.sql` | Liste des sessions connectées. |
| `32_invalid_objects.sql` | Objets invalides par propriétaire. |
| `33_get_users_objects.sql` | Nombre d'objets par type et par utilisateur. |
| `34_disable_auto_tasks.sql` | Statut des tâches automatiques de la base. |
| `35a_get_cursor_usage.sql` | Utilisation des curseurs. |
| `35b_cursors_count.sql` | Nombre de curseurs par session. |
| `36_check_failed_cheduler_jobs.sql` | Tâches planifiées (scheduler jobs) en échec. |
| `37_table_statistics_summary.sql` | Résumé des statistiques des tables. |
| `38_dictionary_stats.sql` | Date des dernières statistiques sur le dictionnaire et les objets fixes. |
| `39_feature_usage_statistics.sql` | Fonctionnalités Oracle utilisées. |
| `40_dba_jobs.sql` | Liste des anciens `dba_jobs`. |
| `sql/cdb/01_show_pdbs.sql` | Liste les Pluggable Databases (PDBs) dans une architecture CDB. |
| `asm/01_asm.sql` | Informations sur les diskgroups ASM. |
| `asm/02_asm_alertlog_errors.sql` | Erreurs dans l'alert log de l'instance ASM. |

## Personnalisation

Pour étendre les rapports, vous pouvez simplement ajouter de nouveaux scripts :

- **Pour le rapport serveur** : Ajoutez un script shell (`.sh`) dans le répertoire `sh/`. Il sera automatiquement exécuté.
- **Pour les rapports de base de données** : Ajoutez un script SQL (`.sql`) dans le répertoire `sql/`. Il sera automatiquement exécuté sur chaque base de données.

Assurez-vous que vos scripts sont auto-contenus et formatent leur propre sortie si nécessaire (par exemple, en utilisant `prompt` dans les scripts SQL ou `print_h2` dans les scripts shell).

## Dépannage

- **Erreur `unbound variable`** : Assurez-vous que les variables utilisées dans les scripts sont correctement initialisées. Le script principal utilise `set -euo pipefail`, ce qui le stoppe si une variable non définie est utilisée.
- **Problèmes de connexion SQL** : Vérifiez que l'environnement Oracle est correctement configuré et que l'utilisateur exécutant le script a les permissions `sysdba`.
- **Commandes non trouvées** : Assurez-vous que toutes les commandes utilisées (comme `vmstat`, `iostat`, etc.) sont installées sur le système et présentes dans le `PATH`.
