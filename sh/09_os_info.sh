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

echo "<h2>Espace disque (df -h) :</h2>"
echo "<pre>"
df -h
echo "</pre>"

echo "<h2>Liste des disques disponibles (lsblk -f) :</h2>"
echo "<pre>"
lsblk -f
echo "</pre>"

echo "<h2>Contenu du fichier /etc/fstab :</h2>"
echo "<pre>"
cat /etc/fstab | egrep -v '^#|^$'
echo "</pre>"

echo "<h2>Contenu du contab du compte oracle :</h2>"
echo "<pre>"
crontab -l
echo "</pre>"

echo "<h2>Taille mémoire en Mo (free -m) :</h2>"
echo "<pre>"
free -m
echo "</pre>"

echo "<h2>Caractéristiques CPU (lscpu) :</h2>"
echo "<pre>"
lscpu
echo "</pre>"

echo "<h2>Limites de l'utilisateur "oracle" (ulimit -a) :</h2>"
echo "<pre>"
ulimit -a | sort
echo "</pre>"

echo "<h2>Les 50 dernières erreur dans /var/log/messages :</h2>"
echo "<pre>"
cat /var/log/messages* | egrep -i 'error|failed' 
echo "</pre>"
