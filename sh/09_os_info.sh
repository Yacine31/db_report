#!/bin/bash
# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Script principal ---

os_type=$(uname -s)

print_h2 "Uptime"
run_and_print "uptime"

case "$os_type" in
    AIX)
        print_h2 "Espace disque (lsfs)"
        run_and_print "lsfs"
        ;;
    Linux)
        print_h2 "Contenu du fichier /etc/fstab"
        run_and_print "cat /etc/fstab | egrep -v '^#|^$'"
        ;;
esac

print_h2 "Contenu du contab du compte oracle"
run_and_print "crontab -l"

case "$os_type" in
    AIX)
        print_h2 "Espace disque (df -g)"
        run_and_print "df -g"
        ;;
    Linux)
        print_h2 "Espace disque (df -h)"
        run_and_print "df -h"
        ;;
esac

case "$os_type" in
    Linux)
        print_h2 "Liste des disques disponibles (lsblk)"
        run_and_print "lsblk"

        print_h2 "Taille mémoire en Mo (free -m)"
        run_and_print "free -m"

        print_h2 "Caractéristiques CPU (lscpu)"
        run_and_print "lscpu"

        log_info "Exécution du script : ${0} .... pause de 20 secondes pour vmstat"
        print_h2 "Statistiques VM (vmstat 2 20)"
        run_and_print "vmstat 2 20"
        log_info "Exécution du script : ${0} .... suite de la collecte"

        print_h2 "Top 10 processus par utilisation CPU (ps --width 150)"
        run_and_print "ps -eo pid,user,%cpu,%mem,vsz,rss,tty,stat,start,time,command --sort=-%cpu --width 1000 | head -n 17 | cut -c 1-180"

        print_h2 "Derniers messages du noyau (dmesg -T | tail -n 30)"
        if sudo -ln &> /dev/null; then
            run_and_print "sudo dmesg -T | tail -n 30"
        else
            echo "<pre>L'utilisateur n'a pas les droits sudo pour exécuter dmesg.</pre>"
        fi

        print_h2 "Les 30 dernières erreurs dans /var/log/messages"
        if sudo -ln &> /dev/null; then
            run_and_print "sudo cat /var/log/messages | egrep -i 'error|failed' | tail -30"
        else
            echo "<pre>L'utilisateur n'a pas les droits sudo pour lire les fichiers log.</pre>"
        fi
        ;;
esac

case "$os_type" in
    AIX)
        print_h2 "Configuration système (prtconf)"
        run_and_print "prtconf"
        ;;
esac


