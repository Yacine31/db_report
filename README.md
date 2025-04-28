Ensemble de scripts qui génèrent des rapports html avec quelques infos du serveur, les bases de données en cours d'exécution, les fichiers, les logs et les sauvegardes

## Sous Linux
```bash
git clone https://github.com/Yacine31/db_report
cd db_report
# Copier le fichier .env.local dans .env
cp .env.lcal .env
# Executer le script
bash rapport_bdd.sh
```

Le résultat est dans le sous répertoire ``` output/YYYYMMDD ```



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
