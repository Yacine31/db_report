
Exemple de script qui génère un rapport html avec quelques infos de la base, les fichiers, les logs et les sauvegardes

## Sous Linux
```bash
git clone https://github.com/Yacine31/db_report
cd db_report
sh -x rapport_bdd.sh
```

il est possible de générer plusieurs CSV avec la commande :
```bash
sh rapport_bdd_csv.sh
```
Un ensemble de fichiers CSV est généré sous format zip 


## Sous Windows
Télécharger le zip ici : [https://github.com/Yacine31/db_report/archive/refs/heads/main.zip](https://github.com/Yacine31/db_report/archive/refs/heads/main.zip)

- Décompresser dans c:\db_report
- Exécuter le script rapport_bdd.cmd

Ou avec GIT : 
Installer git [https://git-scm.com/download/win](https://git-scm.com/download/win)
```cmd
cd /d c:\
git clone https://github.com/Yacine31/db_report
cd db_report
rapport_bdd.cmd
```
