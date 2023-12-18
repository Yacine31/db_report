# faire des commandes pour AIX et pour Linux
os_type=$(uname -s)

echo "<h2>Bases de données en cours d'exécution :</h2>"
echo "<pre>"
ps -ef | grep pmon | grep -v grep 
echo "</pre>"

echo "<h2>Listeners en cours d'exécution :</h2>"
echo "<pre>"
ps -ef | grep tnslsnr| grep -v grep 
echo "</pre>"

echo "<h2>Uptime :</h2>"
echo "<pre>"
uptime
echo "</pre>"

echo "<h2>Contenu du fichier /etc/fstab :</h2>"
echo "<pre>"
cat /etc/fstab | egrep -v '^#|^$'
echo "</pre>"

echo "<h2>Contenu du contab du compte oracle :</h2>"
echo "<pre>"
crontab -l
echo "</pre>"

echo "<h2>Limites de l'utilisateur "oracle" (ulimit -a) :</h2>"
echo "<pre>"
ulimit -a | sort
echo "</pre>"

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
		echo "<h2>Liste des disques disponibles (lsblk -f) :</h2>"
		echo "<pre>"
		lsblk -f
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


