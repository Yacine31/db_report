# faire des commandes pour AIX et pour Linux
os_type=$(uname -s)

# Function to execute command and format output
execute_command() {
    command="$1"
    output="$(eval "$command" 2>&1)"  # Capture both stdout and stderr using eval
    # Print the command and its output in the specified format
    echo "--- Commande ---"
    echo "$command"
    echo "--- Résultat ---"
    echo "$output"
    echo "--- Fin Bloc ---"
}

execute_command "ps -ef | grep pmon | grep -v grep"
execute_command "ps -ef | grep tnslsnr | grep -v grep"

# Listener status
ps -ef | grep tnslsnr | egrep -i " LISTENER |${ORACLE_SID}" | grep -v grep | while read l
do
    binary_path=$(echo $l | perl -lne 'print $1 if /(\S*tnslsnr\S*)/' | sed 's#/bin/tnslsnr##')
    listener_name=$(echo $l | perl -lne 'print $1 if /\btnslsnr\s+(\S+)/' | sed 's/tnslsnr //')
    lsnrctl_command="$binary_path/bin/lsnrctl status $listener_name"
    export TNS_ADMIN=$binary_path/network/admin
    execute_command "$lsnrctl_command"
done

execute_command "uptime"

case "$os_type" in
    AIX)
        execute_command "lsfs"
        ;;
    Linux)
        execute_command "cat /etc/fstab | egrep -v '^#|^$'"
        ;;
esac

execute_command "crontab -l"
execute_command "ulimit -a | sort"

case "$os_type" in
    AIX)
        execute_command "df -g"
        ;;
    Linux)
        execute_command "df -h"
        ;;
esac

case "$os_type" in
    Linux)
        execute_command "lsblk"
        execute_command "free -m"
        execute_command "lscpu"
        if sudo -l &> /dev/null ; then
            execute_command "sudo cat /var/log/messages | egrep -i 'error|failed' | tail -50"
        else
            echo "--- Commande ---"
            echo "sudo cat /var/log/messages | egrep -i 'error|failed' | tail -50"
            echo "--- Résultat ---"
            echo "L'utilisateur n'a les droits pour lire les fichiers log."
            echo "--- Fin Bloc ---"
        fi
        ;;
esac

case "$os_type" in
    AIX)
        execute_command "prtconf"
        ;;
esac
