echo "<h2>Statut des listeners :</h2>"
ps -ef | grep tnslsnr| grep -v grep | while read l
do
	# Récupérer le chemin du binaire tnslsnr à partir de la sortie de ps
	binary_path=$(echo $l | awk '{print $8}' | sed 's/tnslsnr/lsnrctl/')
	# Extraire le nom du listener
	listener_name=$(echo $l | awk '{print $9}')
	# Construire la commande lsnrctl status
	lsnrctl_command="$binary_path status $listener_name"
	# exécuter la commande
	echo "<pre>"
	echo "$lsnrctl_command"
	echo "</pre>"
done