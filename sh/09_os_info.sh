#!/bin/bash

# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Script principal ---

#!/bin/bash

# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Script principal ---

os_type=$(uname -s)

print_h2 "Bases de données en cours d'exécution"
run_and_print "ps -ef | grep pmon | grep -v grep"

print_h2 "Listeners en cours d'exécution"
run_and_print "ps -ef | grep tnslsnr | grep -v grep"

print_h2 "Statut du listener : ${listener_name}"
# Boucle pour le statut du listener, car elle est plus complexe
ps -ef | grep tnslsnr | egrep -i " LISTENER |${ORACLE_SID}" | grep -v grep | while read -r l; do
  binary_path=$(echo "$l" | perl -lne 'print $1 if /(\S*tnslsnr\S*)/' | sed 's#/bin/tnslsnr##')
  listener_name=$(echo "$l" | perl -lne 'print $1 if /\btnslsnr\s+(\S+)/' | sed 's/tnslsnr //')
  
  if [ -n "$binary_path" ] && [ -n "$listener_name" ]; then
    export TNS_ADMIN="$binary_path/network/admin"
    lsnrctl_command="$binary_path/bin/lsnrctl status $listener_name"
    # echo "<b>Listener: ${listener_name}</b>"
    run_and_print "$lsnrctl_command"
  fi
done

print_h2 "Uptime"
run_and_print "uptime"

case "$os_type" in
    AIX)
        print_h2 "Espace disque (lsfs)"
        run_and_print "lsfs"
        print_h2 "Espace disque (lsfs)"
        run_and_print "lsfs"
        ;;
    Linux)
        print_h2 "Contenu du fichier /etc/fstab"
        run_and_print "cat /etc/fstab | egrep -v '^#|^$'"
        print_h2 "Contenu du fichier /etc/fstab"
        run_and_print "cat /etc/fstab | egrep -v '^#|^$'"
        ;;
esac

print_h2 "Contenu du contab du compte oracle"
run_and_print "crontab -l"
print_h2 "Contenu du contab du compte oracle"
run_and_print "crontab -l"

print_h2 "Limites de l'utilisateur (ulimit -a)"
run_and_print "ulimit -a | sort"
print_h2 "Limites de l'utilisateur (ulimit -a)"
run_and_print "ulimit -a | sort"

case "$os_type" in
    AIX)
        print_h2 "Espace disque (df -g)"
        run_and_print "df -g"
        print_h2 "Espace disque (df -g)"
        run_and_print "df -g"
        ;;
    Linux)
        print_h2 "Espace disque (df -h)"
        run_and_print "df -h"
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

        print_h2 "Statistiques VM (vmstat 2 20)"
        run_and_print "vmstat 2 20"

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
        print_h2 "Liste des disques disponibles (lsblk)"
        run_and_print "lsblk"

        print_h2 "Taille mémoire en Mo (free -m)"
        run_and_print "free -m"

        print_h2 "Caractéristiques CPU (lscpu)"
        run_and_print "lscpu"

        print_h2 "Statistiques VM (vmstat 2 20)"
        run_and_print "vmstat 2 20"

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
        print_h2 "Configuration système (prtconf)"
        run_and_print "prtconf"
        ;;
esac


