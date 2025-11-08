# Légende des Commandes Linux

Ce document explique la sortie des commandes Linux les plus complexes utilisées dans les rapports pour faciliter leur interprétation.

## `vmstat 2 20`

La commande `vmstat` (Virtual Memory Statistics) fournit des informations sur les processus, la mémoire, la pagination, les I/O bloc, les interruptions et l'activité CPU. La commande `vmstat 2 20` affiche 20 rapports à 2 secondes d'intervalle.

```
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0      0 123456  10000 500000    0    0     0    10  100  200  1  1 98  0  0
```

- **procs**
  - `r`: Nombre de processus en attente d'exécution. Une valeur élevée et persistante indique une charge CPU importante.
  - `b`: Nombre de processus en sommeil ininterrompu (généralement en attente d'I/O).
- **memory** (en kilo-octets)
  - `swpd`: Mémoire virtuelle utilisée (swap).
  - `free`: Mémoire vive libre.
  - `buff`: Mémoire utilisée comme "buffers".
  - `cache`: Mémoire utilisée comme "cache" pour les fichiers.
- **swap**
  - `si`: Mémoire "swappée" depuis le disque (swap-in) par seconde. Une valeur non nulle indique une pression sur la mémoire.
  - `so`: Mémoire "swappée" vers le disque (swap-out) par seconde.
- **io** (blocs par seconde)
  - `bi`: Blocs reçus d'un périphérique bloc (read).
  - `bo`: Blocs envoyés à un périphérique bloc (write).
- **system**
  - `in`: Nombre d'interruptions par seconde.
  - `cs`: Nombre de changements de contexte par seconde.
- **cpu** (en pourcentage du temps CPU total)
  - `us`: Temps passé à exécuter du code utilisateur (non-kernel).
  - `sy`: Temps passé à exécuter du code noyau (kernel).
  - `id`: Temps d'inactivité (idle).
  - `wa`: Temps passé à attendre une I/O. Une valeur élevée indique un goulot d'étranglement disque.
  - `st`: Temps "volé" à une machine virtuelle (Steal Time).

---

## `top -b -n 1`

La commande `top` donne un aperçu en temps réel des processus en cours. `top -b -n 1` l'exécute en mode "batch" pour une seule itération.

### En-tête

- **Ligne 1**: `top - ... up ... users, load average: ...`
  - `up`: Uptime du serveur.
  - `load average`: Charge moyenne du système sur 1, 5 et 15 minutes.
- **Ligne 2**: `Tasks: ... total, ... running, ... sleeping, ...`
  - Résumé de l'état des processus.
- **Ligne 3**: `%Cpu(s): ... us, ... sy, ... ni, ... id, ... wa, ...`
  - Utilisation détaillée du CPU (similaire à `vmstat`).
- **Lignes 4 & 5**: `MiB Mem : ... total, ... free, ... used, ...` et `MiB Swap: ...`
  - Utilisation de la mémoire RAM et du swap.

### Liste des processus

| Colonne | Description |
| :--- | :--- |
| `PID` | ID du processus. |
| `USER` | Utilisateur propriétaire du processus. |
| `PR` | Priorité du processus. |
| `NI` | Valeur "Nice" (influence la priorité). |
| `VIRT` | Mémoire virtuelle utilisée par le processus. |
| `RES` | Mémoire résidente (physique) utilisée. |
| `SHR` | Mémoire partagée. |
| `S` | Statut du processus (R=Running, S=Sleeping, Z=Zombie, etc.). |
| `%CPU` | Pourcentage du CPU utilisé par le processus. |
| `%MEM` | Pourcentage de la mémoire physique utilisée. |
| `TIME+` | Temps CPU total utilisé par le processus. |
| `COMMAND` | Nom de la commande. |

---

## `dmesg`

La commande `dmesg` affiche les messages du noyau (kernel ring buffer). C'est un outil essentiel pour diagnostiquer les problèmes matériels et de pilotes.

La sortie contient des messages horodatés (en secondes depuis le démarrage) décrivant les événements détectés par le noyau :
- Initialisation du matériel (disques, cartes réseau, etc.).
- Erreurs de pilotes.
- Erreurs I/O sur les disques.
- Problèmes de mémoire (ex: OOM Killer).

Exemple de ligne :
`[12345.678901] sd 2:0:0:0: [sda] Attached SCSI disk`
Cette ligne indique qu'à 12345 secondes après le démarrage, le noyau a attaché un disque SCSI identifié comme `sda`.

---

## `iostat -dx 1 5` (Suggestion)

`iostat` rapporte les statistiques d'I/O pour les périphériques. C'est l'outil principal pour diagnostiquer les goulots d'étranglement disque.

- **`r/s`, `w/s`**: Nombre de lectures/écritures par seconde.
- **`rkB/s`, `wkB/s`**: Kilo-octets lus/écrits par seconde.
- **`r_await`, `w_await`**: Temps moyen d'attente (en ms) pour les requêtes de lecture/écriture. Des valeurs élevées indiquent une latence.
- **`aqu-sz`**: Taille moyenne de la file d'attente des requêtes. Si cette valeur est élevée, le disque est probablement surchargé.
- **`%util`**: Pourcentage de temps pendant lequel le disque était actif. Une valeur proche de 100% indique que le disque est saturé.

---

## `ss -s` (Suggestion)

`ss` est un outil moderne pour inspecter les sockets (connexions réseau). `ss -s` fournit un résumé statistique.

```
Total: 128 (kernel 132)
TCP:   10 (estab 3, closed 2, orphaned 0, syn-recv 0, time-wait 2/0), ports 0
...
```

- **`Total`**: Nombre total de sockets.
- **`TCP`**: Statistiques pour les sockets TCP.
  - `estab`: Connexions établies.
  - `closed`: Connexions fermées.
  - `time-wait`: Sockets en état `TIME_WAIT`, ce qui peut indiquer un grand nombre de connexions courtes et rapides.
