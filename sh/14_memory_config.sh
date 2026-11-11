#!/bin/bash
# Configuration memoire : HugePages, Transparent HugePages, /dev/shm, et SGA des instances
source "$(dirname "$0")/utils.sh"

[ "$(uname -s)" = "Linux" ] || exit 0

print_h2 "Memory and HugePages (/proc/meminfo)"
run_and_print "grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree|HugePages_Total|HugePages_Free|HugePages_Rsvd|Hugepagesize|AnonHugePages)' /proc/meminfo"

print_h2 "Transparent HugePages"
# Oracle recommande de desactiver les Transparent HugePages : la valeur active est entre crochets
run_and_print "cat /sys/kernel/mm/transparent_hugepage/enabled"

print_h2 "Shared Memory Filesystem (/dev/shm)"
run_and_print "df -h /dev/shm"

# --- SGA des instances demarrees comparee aux HugePages configurees ---
print_h2 "SGA of Running Instances vs HugePages"
hp_total=$(awk '/^HugePages_Total:/ {print $2}' /proc/meminfo)
hp_free=$(awk '/^HugePages_Free:/ {print $2}' /proc/meminfo)
hp_size_kb=$(awk '/^Hugepagesize:/ {print $2}' /proc/meminfo)
hp_total_mb=$(( ${hp_total:-0} * ${hp_size_kb:-0} / 1024 ))
hp_used_mb=$(( ( ${hp_total:-0} - ${hp_free:-0} ) * ${hp_size_kb:-0} / 1024 ))

sga_total_mb=0
echo "<br><pre>"
printf '%-16s %10s   %s\n' "Instance" "SGA MB" "use_large_pages"
for sid in $(list_db_sids); do
  set_oracle_env "$sid"
  sga_mb=$(sql_value "select round(sum(value)/1024/1024) from v\$sga;")
  large_pages=$(sql_value "select value from v\$parameter where name = 'use_large_pages';")
  case "$sga_mb" in
    ''|*[!0-9]*) sga_mb=0; large_pages="(instance not reachable)" ;;
  esac
  printf '%-16s %10s   %s\n' "$sid" "$sga_mb" "$large_pages" | html_escape
  sga_total_mb=$(( sga_total_mb + sga_mb ))
done
echo ""
printf '%-28s %8s MB\n' "Total SGA (databases):" "$sga_total_mb"
printf '%-28s %8s MB\n' "HugePages configured:" "$hp_total_mb"
printf '%-28s %8s MB\n' "HugePages in use:" "$hp_used_mb"
echo ""
if [ "$hp_total_mb" -eq 0 ]; then
  echo "HugePages are not configured: the SGA uses regular 4 KB pages."
elif [ "$hp_total_mb" -lt "$sga_total_mb" ]; then
  echo "HugePages are smaller than the total SGA: at least one instance cannot fit entirely in HugePages."
else
  echo "HugePages are large enough for the total SGA of the running databases."
fi
echo "ASM and other non-database instances are not counted."
echo "</pre>"
