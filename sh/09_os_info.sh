#!/bin/bash
# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Fonctions ---

# Résumé quotidien de l'historique sar pour le swap (un jour par ligne, le plus récent en premier).
# sar -W donne l'activité de swap (pages/s), sar -S le taux d'occupation du swap.
# Les moyennes sont recalculées sur les échantillons : après un redémarrage, sar affiche
# plusieurs lignes "Average" pour une même journée.
# Retourne 1 si aucun historique sysstat n'est disponible.
sar_swap_history() {
  local sa_dir="" d f w s found=1
  for d in /var/log/sa /var/log/sysstat; do
    if [ -d "$d" ]; then sa_dir="$d"; break; fi
  done
  [ -n "$sa_dir" ] || return 1

  printf '%-12s %14s %14s %14s %13s\n' "Date" "avg pswpin/s" "avg pswpout/s" "max pswpout/s" "max %swpused"
  # shellcheck disable=SC2012
  for f in $(ls -t "$sa_dir"/sa[0-9]* 2>/dev/null | head -10); do
    w=$(LC_ALL=C S_TIME_FORMAT=ISO sar -W -f "$f" 2>/dev/null | awk '
          NR==1 { d=$4 }
          /^[0-9]/ && $NF ~ /^[0-9.]+$/ { swin+=$(NF-1); swout+=$NF; n++; if ($NF+0 > mx) mx=$NF+0 }
          END { if (n > 0) printf "%s %.2f %.2f %.2f", d, swin/n, swout/n, mx }')
    s=$(LC_ALL=C S_TIME_FORMAT=ISO sar -S -f "$f" 2>/dev/null | awk '
          /^[0-9]/ && $(NF-2) ~ /^[0-9.]+$/ { if ($(NF-2)+0 > mx) mx=$(NF-2)+0 }
          END { printf "%.2f", mx }')
    if [ -n "$w" ]; then
      # shellcheck disable=SC2086
      printf '%-12s %14s %14s %14s %13s\n' $w "$s"
      found=0
    fi
  done
  return $found
}

# --- Script principal ---

os_type=$(uname -s)

print_h2 "Uptime"
run_and_print "uptime"

case "$os_type" in
    AIX)
        print_h2 "Disk Space (lsfs)"
        run_and_print "lsfs"
        ;;
    Linux)
        print_h2 "Content of /etc/fstab"
        run_and_print "cat /etc/fstab | egrep -v '^#|^$'"
        ;;
esac

print_h2 "Oracle OS User Crontab Content"
run_and_print "crontab -l"

case "$os_type" in
    AIX)
        print_h2 "Disk Space Usage (df -g)"
        run_and_print "df -g"
        ;;
    Linux)
        print_h2 "Disk Space Usage (df -h)"
        run_and_print "df -h"
        ;;
esac

case "$os_type" in
    Linux)
        print_h2 "Available Disks (lsblk)"
        run_and_print "lsblk"

        print_h2 "Memory Size in MB (free -m)"
        run_and_print "free -m"

        # --- Swap ---
        # Compteurs cumulés depuis le démarrage : à lire avec l'uptime ci-dessus.
        # 0 = le serveur n'a jamais swappé depuis le boot.
        print_h2 "Swap Activity Since Boot (pages swapped in/out)"
        run_and_print "grep -E '^(pswpin|pswpout) ' /proc/vmstat"

        print_h2 "Top 10 Processes by Swap Usage (VmSwap)"
        run_and_print "awk '/^Name:/{n=\$2} /^Pid:/{p=\$2} /^VmSwap:/ && \$2>0 {printf \"%10d kB  pid %-8s %s\\n\",\$2,p,n}' /proc/[0-9]*/status 2>/dev/null | sort -rn | head -10 | grep . || echo 'No process is using swap.'"

        if command -v sar &>/dev/null; then
            print_h2 "Swap History per Day (sar -W / sar -S)"
            echo "<br><pre>"
            if sar_history=$(sar_swap_history); then
                echo "${sar_history}" | html_escape
            else
                echo "No sysstat history available (sar)."
            fi
            echo "</pre>"
        fi

        print_h2 "CPU Characteristics (lscpu)"
        run_and_print "lscpu"

        # Échantillon vmstat en direct : uniquement sur demande (option --vmstat), il dure environ 40 secondes
        if [ "${DB_REPORT_VMSTAT:-0}" = "1" ]; then
            print_h2 "VM Statistics (vmstat 2 20)"
            run_and_print "vmstat 2 20"
        fi

        print_h2 "Top 10 Processes by CPU Usage"
        run_and_print "ps -eo pid,user,%cpu,%mem,vsz,rss,tty,stat,start,time,command --sort=-%cpu --width 1000 | head -n 17 | cut -c 1-180"

        print_h2 "Last Kernel Messages (dmesg)"
        if sudo -n dmesg &>/dev/null 2>&1; then
            run_and_print "sudo dmesg -T | tail -n 30"
        else
            echo "<pre>L'utilisateur n'a pas les droits sudo pour exécuter dmesg.</pre>"
        fi

        print_h2 "Last 30 Errors in /var/log/messages"
        if sudo -n cat /var/log/messages &>/dev/null 2>&1; then
            run_and_print "sudo cat /var/log/messages | egrep -i 'error|failed' | tail -30"
        else
            echo "<pre>L'utilisateur n'a pas les droits sudo pour lire les fichiers log.</pre>"
        fi
        ;;
esac

case "$os_type" in
    AIX)
        print_h2 "System Configuration (prtconf)"
        run_and_print "prtconf"
        ;;
esac
