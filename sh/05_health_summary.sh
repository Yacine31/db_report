#!/bin/bash
# Synthese des points d'attention du serveur : une ligne par controle, avec sa valeur, son seuil
# et un statut OK / WARNING / CRITICAL / INFO. Le detail se trouve dans les sections suivantes.
source "$(dirname "$0")/utils.sh"

[ "$(uname -s)" = "Linux" ] || exit 0

# ============================== SEUILS ==============================
FS_WARN_PCT=85          # filesystems : % utilise
FS_CRIT_PCT=95
SWAP_WARN_PCT=10        # swap : % utilise
SWAP_CRIT_PCT=50
MEM_AVAIL_WARN_PCT=10   # memoire disponible (MemAvailable) : % minimum de la memoire totale
# =====================================================================

# Ajoute une ligne au tableau : controle, valeur, seuil, statut
check_row() {
  printf '<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n' \
    "$(printf '%s' "$1" | html_escape)" "$(printf '%s' "$2" | html_escape)" \
    "$(printf '%s' "$3" | html_escape)" "$4"
}

# Lit une valeur de /proc/meminfo (en kB)
meminfo() {
  awk -v key="$1:" '$1 == key {print $2}' /proc/meminfo
}

print_h2 "Server Health Summary"
echo "<table>"
echo "<tr><th>Check</th><th>Value</th><th>Threshold</th><th>Status</th></tr>"

# --- Filesystems (hors tmpfs/devtmpfs) ; timeout au cas ou un montage NFS ne repond plus ---
fs_data=$(timeout 20 df -P -x tmpfs -x devtmpfs 2>/dev/null | awk 'NR > 1 {gsub("%", "", $5); print $5, $6}')
if [ -z "$fs_data" ]; then
  check_row "Filesystem usage" "df did not answer within 20 seconds" "warn ${FS_WARN_PCT}% / crit ${FS_CRIT_PCT}%" "WARNING"
else
  fs_total=$(echo "$fs_data" | wc -l)
  fs_above=$(echo "$fs_data" | awk -v w="$FS_WARN_PCT" '$1 >= w' | wc -l)
  fs_max=$(echo "$fs_data" | sort -rn | head -1)
  fs_max_pct=${fs_max%% *}
  fs_status="OK"
  [ "$fs_max_pct" -ge "$FS_WARN_PCT" ] && fs_status="WARNING"
  [ "$fs_max_pct" -ge "$FS_CRIT_PCT" ] && fs_status="CRITICAL"
  check_row "Filesystem usage" "${fs_above} of ${fs_total} above ${FS_WARN_PCT}%, highest: ${fs_max#* } ${fs_max_pct}%" \
    "warn ${FS_WARN_PCT}% / crit ${FS_CRIT_PCT}%" "$fs_status"
fi

# --- Memoire disponible ---
mem_total=$(meminfo MemTotal)
mem_avail=$(meminfo MemAvailable)
if [ -n "$mem_total" ] && [ -n "$mem_avail" ] && [ "$mem_total" -gt 0 ]; then
  mem_pct=$(( mem_avail * 100 / mem_total ))
  mem_status="OK"
  [ "$mem_pct" -lt "$MEM_AVAIL_WARN_PCT" ] && mem_status="WARNING"
  check_row "Available memory" "$(( mem_avail / 1024 )) MB of $(( mem_total / 1024 )) MB (${mem_pct}%)" \
    "warn below ${MEM_AVAIL_WARN_PCT}%" "$mem_status"
fi

# --- Swap utilise ---
swap_total=$(meminfo SwapTotal)
swap_free=$(meminfo SwapFree)
if [ -n "$swap_total" ] && [ "$swap_total" -gt 0 ]; then
  swap_pct=$(( (swap_total - swap_free) * 100 / swap_total ))
  swap_status="OK"
  [ "$swap_pct" -ge "$SWAP_WARN_PCT" ] && swap_status="WARNING"
  [ "$swap_pct" -ge "$SWAP_CRIT_PCT" ] && swap_status="CRITICAL"
  check_row "Swap usage" "$(( (swap_total - swap_free) / 1024 )) MB of $(( swap_total / 1024 )) MB (${swap_pct}%)" \
    "warn ${SWAP_WARN_PCT}% / crit ${SWAP_CRIT_PCT}%" "$swap_status"
else
  check_row "Swap usage" "no swap configured" "warn ${SWAP_WARN_PCT}% / crit ${SWAP_CRIT_PCT}%" "INFO"
fi

# --- Charge systeme sur 15 minutes rapportee au nombre de CPU ---
load15=$(awk '{print $3}' /proc/loadavg)
cpus=$(nproc 2>/dev/null || echo 1)
load_status=$(awk -v l="$load15" -v c="$cpus" 'BEGIN { print (l > c) ? "WARNING" : "OK" }')
check_row "Load average (15 min)" "${load15} for ${cpus} CPU(s)" "warn above the number of CPUs" "$load_status"

# --- HugePages comparees a la SGA des bases demarrees ---
hp_total=$(meminfo HugePages_Total)
hp_size_kb=$(meminfo Hugepagesize)
hp_total_mb=$(( ${hp_total:-0} * ${hp_size_kb:-0} / 1024 ))
sga_total_mb=0
for sid in $(list_db_sids); do
  set_oracle_env "$sid"
  sga_mb=$(sql_value "select round(sum(value)/1024/1024) from v\$sga;")
  case "$sga_mb" in
    ''|*[!0-9]*) sga_mb=0 ;;
  esac
  sga_total_mb=$(( sga_total_mb + sga_mb ))
done
if [ "$sga_total_mb" -eq 0 ]; then
  check_row "HugePages vs total SGA" "no running database" "HugePages >= total SGA" "INFO"
elif [ "$hp_total_mb" -eq 0 ]; then
  check_row "HugePages vs total SGA" "HugePages not configured, total SGA ${sga_total_mb} MB" "HugePages >= total SGA" "WARNING"
elif [ "$hp_total_mb" -lt "$sga_total_mb" ]; then
  check_row "HugePages vs total SGA" "HugePages ${hp_total_mb} MB, total SGA ${sga_total_mb} MB" "HugePages >= total SGA" "WARNING"
else
  check_row "HugePages vs total SGA" "HugePages ${hp_total_mb} MB, total SGA ${sga_total_mb} MB" "HugePages >= total SGA" "OK"
fi

# --- Transparent HugePages : la valeur active est entre crochets ---
if [ -r /sys/kernel/mm/transparent_hugepage/enabled ]; then
  thp=$(sed 's/.*\[\(.*\)\].*/\1/' /sys/kernel/mm/transparent_hugepage/enabled)
  thp_status="OK"
  [ "$thp" = "never" ] || thp_status="WARNING"
  check_row "Transparent HugePages" "$thp" "never expected" "$thp_status"
fi

# --- Synchronisation horaire ---
if command -v chronyc &>/dev/null; then
  leap=$(chronyc tracking 2>/dev/null | awk -F': *' '/^Leap status/ {print $2}')
  if [ "$leap" = "Normal" ]; then
    check_row "Time synchronization (chrony)" "synchronized" "synchronized expected" "OK"
  else
    check_row "Time synchronization (chrony)" "${leap:-chronyd not reachable}" "synchronized expected" "WARNING"
  fi
fi

# --- Listener ---
listeners=$(ps -eo args | grep -c '[t]nslsnr')
if [ "$listeners" -gt 0 ]; then
  check_row "Running listeners" "$listeners" "at least 1" "OK"
else
  check_row "Running listeners" "0" "at least 1" "CRITICAL"
fi

# --- Bases declarees dans /etc/oratab mais non demarrees ---
# Seules les entrees dont le home contient bin/oracle sont des bases (pas les homes agent, OMS, ...).
if [ -r /etc/oratab ]; then
  running=" $(list_db_sids | tr '\n' ' ')"
  stopped=""
  stopped_auto=""
  while IFS=: read -r o_sid o_home o_auto; do
    case "$o_sid" in
      ''|\#*|+*|-*|\**) continue ;;
    esac
    [ -x "${o_home}/bin/oracle" ] || continue
    case "$running" in
      *" ${o_sid} "*) ;;
      *)
        stopped="${stopped} ${o_sid}"
        [ "${o_auto%% *}" = "Y" ] && stopped_auto="${stopped_auto} ${o_sid}"
        ;;
    esac
  done < /etc/oratab
  if [ -z "$stopped" ]; then
    check_row "Databases in /etc/oratab not running" "none" "none expected for autostart (Y) entries" "OK"
  elif [ -n "$stopped_auto" ]; then
    check_row "Databases in /etc/oratab not running" "${stopped# } (autostart Y:${stopped_auto})" "none expected for autostart (Y) entries" "WARNING"
  else
    check_row "Databases in /etc/oratab not running" "${stopped# } (autostart N)" "none expected for autostart (Y) entries" "INFO"
  fi
fi

echo "</table>"
