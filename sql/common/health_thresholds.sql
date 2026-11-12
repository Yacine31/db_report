-- Seuils des controles de la synthese de sante, partages par sql/00a_health_summary.sql
-- (controles possibles sur une base montee) et sql/00b_health_summary_open.sql (base ouverte).
-- Appele apres SET DEFINE ON.

-- ============================== SEUILS ==============================
-- Tablespaces : % utilise par rapport a la taille maximale (autoextend compris)
DEFINE tbs_warn_pct     = 85
DEFINE tbs_crit_pct     = 95
-- Fast Recovery Area : % non recuperable
DEFINE fra_warn_pct     = 80
DEFINE fra_crit_pct     = 90
-- Age du dernier backup reussi de la base (full ou incremental), en jours
DEFINE backup_warn_days = 2
DEFINE backup_crit_days = 7
-- Fenetre d'analyse (alert log, jobs RMAN et scheduler en echec), en jours : 30, le rapport
-- etant prevu pour une execution mensuelle
DEFINE recent_days      = 30
-- Age du dernier patch SQL applique (datapatch), en jours
DEFINE patch_warn_days  = 200
DEFINE patch_crit_days  = 400
-- Pic d'utilisation du parametre processes, en %
DEFINE proc_warn_pct    = 80
DEFINE proc_crit_pct    = 90
-- Sequences : % de la valeur maximale
DEFINE seq_warn_pct     = 80
-- Data Guard : transport lag et apply lag de la standby, en minutes
DEFINE dg_lag_warn_min  = 5
DEFINE dg_lag_crit_min  = 15
-- =====================================================================
