echo "<h2>Running Databases</h2>"
echo "<pre>"
ps -ef | grep pmon | grep -v grep 
echo "</pre>"

echo "<h2>Running listeners</h2>"
echo "<pre>"
ps -ef | grep tnslsnr| grep -v grep 
echo "</pre>"

echo "<h2>Disk Size df -h</h2>"
echo "<pre>"
df -h
echo "</pre>"

echo "<h2>lsblk -f </h2>"
echo "<pre>"
lsblk -f
echo "</pre>"

echo "<h2>cat /etc/fstab </h2>"
echo "<pre>"
cat /etc/fstab | egrep -v '^#|^$'
echo "</pre>"

echo "<h2>Memory Size (Mo) : free -m </h2>"
echo "<pre>"
free -m
echo "</pre>"

echo "<h2>lscpu </h2>"
echo "<pre>"
lscpu
echo "</pre>"

echo "<h2>ulimit -a </h2>"
echo "<pre>"
ulimit -a | sort
echo "</pre>"

