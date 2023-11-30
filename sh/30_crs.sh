# script à exécuter si couche grid/crs

count=$(ps -ef | grep ohasd | grep -v grep | wc -l)

if [ $count -gt 0 ]; then

	echo "<h2>Services CRS</h2>"
	# les process dbvisit en cours 

	BIN_DIR=$(dirname $(ps -ef | grep ohasd.bin | grep -v grep | awk '{print $8}'))
	echo "<pre>"
	${BIN_DIR}/crsctl status res -t
	echo "</pre>"
fi