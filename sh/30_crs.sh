#!/bin/bash

# Importe les fonctions utilitaires
source "$(dirname "$0")/utils.sh"

# --- Script principal ---

# script à exécuter si couche grid/crs

count=$(ps -ef | grep ohasd | grep -v grep | wc -l)

if [ "$count" -gt 0 ]; then

	print_h2 "Services CRS"

	# BIN_DIR=$(dirname $(ps -ef | grep ohasd.bin | grep -v grep | egrep -o '/.*ohasd\.bin'))
	# la commande egrep -o ne fonctionne pas sous AIX
	# on utilise donc la commande suivante avec awk
	BIN_DIR=$(dirname "$(ps -ef | grep ohasd.bin | grep -v grep | awk '{ match($0, /\/.*ohasd\.bin/); print substr($0, RSTART, RLENGTH) }')")
	# explication de la commande awk :
	# - match($0, /\/.*ohasd\.bin/): Cette partie de la commande awk recherche la première occurrence 
	#	de la séquence "/.*ohasd.bin" dans la ligne.
	# - substr($0, RSTART, RLENGTH): Cette partie extrait la sous-chaîne de la ligne, à partir de 
	#	la position RSTART (où la correspondance commence) jusqu'à la longueur RLENGTH de la correspondance.
	# - Le résultat sera la portion de la chaîne entre le premier / et le mot "ohasd.bin".
	# - la commande dirname retourne le répertoire qui sera utilisé dans BIN_DIR

	if [ -n "$BIN_DIR" ] && [ -x "$BIN_DIR/crsctl" ]; then
		run_and_print "${BIN_DIR}/crsctl status res -t"
	else
		echo "<pre>Impossible de trouver le répertoire d'installation CRS ou crsctl n'est pas exécutable.</pre>"
	fi
fi