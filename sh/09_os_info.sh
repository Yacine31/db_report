# faire des commandes pour AIX et pour Linux
os_type=$(uname -s)

echo "<h2>Bases de données en cours d'exécution :</h2>"
echo "<pre>"
ps -ef | grep pmon | grep -v grep 
echo "</pre>"

echo "<h2>Listeners en cours d'exécution :</h2>"
echo "<pre>"
ps -ef | grep tnslsnr | grep -v grep 
echo "</pre>"

echo "<h2>Statut du listener :</h2>"
# ps -ef | grep tnslsnr | egrep -i "LISTENER_${ORACLE_SID}" | grep -v grep | while read l
ps -ef | grep tnslsnr | egrep -i " LISTENER |${ORACLE_SID}" | grep -v grep | while read l
do
	# Récupérer le chemin ORACLE_HOME à partir de la sortie de ps -ef
	# ---- La commande grep -o ne fonctionne pas sur AIX, on la remplace par perl -lne
	# binary_path=$(echo $l | grep -o '/[^ ]*' | sed 's#/bin/tnslsnr##')
	binary_path=$(echo $l | perl -lne 'print $1 if /(\S*tnslsnr\S*)/' | sed 's#/bin/tnslsnr##')
	# Extraire le nom du listener
	# listener_name=$(echo $l | grep -o 'tnslsnr [^ ]*' | sed 's/tnslsnr //')
	listener_name=$(echo $l | perl -lne 'print $1 if /\btnslsnr\s+(\S+)/' | sed 's/tnslsnr //')
	# Construire la commande lsnrctl status
	lsnrctl_command="$binary_path/bin/lsnrctl status $listener_name"
	# exécuter la commande
	echo "<br><pre>"
	echo $lsnrctl_command
	echo export TNS_ADMIN=$binary_path/network/admin
	export TNS_ADMIN=$binary_path/network/admin
	eval "$lsnrctl_command"
	echo "</pre><br>"
done

echo "<h2>Uptime :</h2>"
echo "<pre>"
uptime
echo "</pre>"

case "$os_type" in
    AIX)
		echo "<h2>Espace disque (lsfs) :</h2>"
		echo "<pre>"
        lsfs
		echo "</pre>"
        ;;
    Linux)
		echo "<h2>Contenu du fichier /etc/fstab :</h2>"
		echo "<pre>"
		cat /etc/fstab | egrep -v '^#|^$'
		echo "</pre>"
        ;;
esac

echo "<h2>Contenu du contab du compte oracle :</h2>"
echo "<pre>"
crontab -l
echo "</pre>"

echo "<h2>Limites de l'utilisateur "oracle" (ulimit -a) :</h2>"
echo "<pre>"
ulimit -a | sort
echo "</pre>"

# espace disque en fonction de l'OS
case "$os_type" in
    AIX)
		echo "<h2>Espace disque (df -g) :</h2>"
		echo "<pre>"
        df -g
		echo "</pre>"
        ;;
    Linux)
		echo "<h2>Espace disque (df -h) :</h2>"
		echo "<pre>"
        df -h
		echo "</pre>"
        ;;
esac


case "$os_type" in
    Linux)
		echo "<h2>Liste des disques disponibles (lsblk) :</h2>"
		echo "<pre>"
		lsblk
		echo "</pre>"

		echo "<h2>Taille mémoire en Mo (free -m) :</h2>"
		echo "<pre>"
		free -m
		echo "</pre>"

		echo "<h2>Caractéristiques CPU (lscpu) :</h2>"
		echo "<pre>"
		lscpu
		echo "</pre>"

		echo "<h2>Les 50 dernières erreur dans /var/log/messages :</h2>"
		if sudo -l &> /dev/null ; then
		    # L'utilisateur a les droits sudo. on continue
			echo "<pre>"
			sudo cat /var/log/messages | egrep -i 'error|failed' | tail -50 
			echo "</pre>"
		else
			echo "<pre>"
		    echo "L'utilisateur n'a les droits pour lire les fichiers log."
			echo "</pre>"
		fi
        ;;
esac

case "$os_type" in
    AIX)
		echo "<h2>Configuration système (prtconf) :</h2>"
		echo "<pre>"
        prtconf
		echo "</pre>"
        ;;
esac


