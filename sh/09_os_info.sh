#!/bin/bash
# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

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

        print_h2 "CPU Characteristics (lscpu)"
        run_and_print "lscpu"

        print_h2 "VM Statistics (vmstat 2 20)"
        run_and_print "vmstat 2 20"

        print_h2 "Top 10 Processes by CPU Usage"
        run_and_print "ps -eo pid,user,%cpu,%mem,vsz,rss,tty,stat,start,time,command --sort=-%cpu --width 1000 | head -n 17 | cut -c 1-180"

        print_h2 "Last Kernel Messages (dmesg)"
        if sudo -ln &> /dev/null; then
            run_and_print "sudo dmesg -T | tail -n 30"
        else
            echo "<pre>L'utilisateur n'a pas les droits sudo pour exécuter dmesg.</pre>"
        fi

        print_h2 "Last 30 Errors in /var/log/messages"
        if sudo -ln &> /dev/null; then
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


