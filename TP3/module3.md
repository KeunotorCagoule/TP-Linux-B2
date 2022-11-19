# Module 3 : Sauvegarde de base de données

Dans cette partie le but va être d'écrire un script `bash` qui récupère le contenu de la base de données utilisée par NextCloud, afin d'être en mesure de restaurer les données plus tard si besoin.

Le script utilisera la commande `mysqldump` qui permet de récupérer le contenu de la base de données sous la forme d'un fichier `.sql`.

Ce fichier `.sql` on pourra ensuite le compresser et le placer dans un dossier dédié afin de l'archiver.

Une fois le script fonctionnel, on créera alors un service qui permet de déclencher l'exécution de ce script dans de bonnes conditions.

Enfin, un *timer* permettra de déclencher l'exécution du *service* à intervalles réguliers.

![Kitten me](../pics/kittenme.jpg)

## I. Script dump

➜ **Créer un utilisateur DANS LA BASE DE DONNEES**

- inspirez-vous des commandes SQL que je vous ai données au TP2
- l'utilisateur doit pouvoir se connecter depuis `localhost`
- il doit avoir les droits sur la base de données `nextcloud` qu'on a créé au TP2
- l'idée est d'avoir un utilisateur qui est dédié aux dumps de la base
  - votre script l'utilisera pour se connecter à la base et extraire les données

```sql
MariaDB [(none)]> CREATE USER 'restore'@'10.102.1.11' IDENTIFIED BY 'toto';
Query OK, 0 rows affected (0.002 sec)

MariaDB [(none)]> RENAME USER 'restore'@'10.102.1.11' to 'restore'@'localhost';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nextcloud.* TO 'restore'@'localhos
t';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```

```sh
# au dessus
# on a créé un utilisateur 'restore'@'localhost' qui a tous les droits sur la base de données 'nextcloud' sur la machine db.tp2.linux
```

➜ **Ecrire le script `bash`**

- il s'appellera `tp3_db_dump.sh`
- il devra être stocké dans le dossier `/srv` sur la machine `db.tp2.linux`
- le script doit commencer par un *shebang* qui indique le chemin du programme qui exécutera le contenu du script
  - ça ressemble à ça si on veut utiliser `/bin/bash` pour exécuter le contenu de notre script :

```
#!/bin/bash
```

- le script doit contenir une commande `mysqldump`
  - qui récupère le contenu de la base de données `nextcloud`
  - en utilisant l'utilisateur précédemment créé
- le fichier `.sql` produit doit avoir **un nom précis** :
  - il doit comporter le nom de la base de données dumpée
  - il doit comporter la date, l'heure la minute et la seconde où a été effectué le dump
  - par exemple : `db_nextcloud_2211162108.sql`
- enfin, le fichier `sql` doit être compressé
  - au format `.zip` ou `.tar.gz`
  - le fichier produit sera stocké dans le dossier `/srv/db_dumps/`
  - il doit comporter la date, l'heure la minute et la seconde où a été effectué le dump

```sh
# création du fichier du script
[roxanne@db srv]$ sudo nano tp3_db_dump.sh
[sudo] password for roxanne:
```

```sh
# on choisit de faire la sauvegarde de la db sur le node master puisque notre nextcloud n'est pas très solicité nous n'aurons donc pas de problème de performance.
# si on avait choisi de faire la sauvegarde sur le node slave, on aurait cependant perdu des données car le node slave aurait peut-être eu un décalage avec les données du node master. On aurait eu un problème d'intégrité.
```

```sh
[roxanne@db srv]$ cat tp3_db_dump.sh
#!/bin/bash
# Last Update : 18/11/2022
# Written by : Roulland Roxanne
# This script will dump the database and save it to a file

# Set the variables
user='restore'
passwd='toto'
db='nextcloud'
ip_serv='localhost'
datesauv=$(date '+%y%m%d_%H%M%S')
name='${db}_${datesauv}'
outputpath="/srv/db_dumps/${name}.sql"

# Dump the database

echo "Backup started for database - ${db}."
mysqldump -h ${ip_serv} -u ${user} -p${passwd} --skip-lock-tables --databases ${db} > $outputpath
if [[ $? == 0 ]]
then
        gzip -c $outputpath > '${outputpath}.gz'
        rm -f $outputpath
        echo "Backup successfully completed."
else 
        echo "Backup failed."
        rm -f outputpath
        exit 1
fi
```

```sh
[roxanne@db srv]$ sudo chmod 744 tp3_db_dump.sh
[roxanne@db srv]$ ls -l
total 4
-rwxr--r--. 1 root root 696 Nov 19 10:49 tp3_db_dump.sh```

> On utilise la notation américaine de la date `yymmdd` avec l'année puis le mois puis le jour, comme ça, un tri alphabétique des fichiers correspond à un tri dans l'ordre temporel :)

## II. Clean it

On va rendre le script un peu plus propre vous voulez bien ?

➜ **Utiliser des variables** déclarées en début de script pour stocker les valeurs suivantes :

- utilisateur de la base de données utiliser pour dump
- son password
- le nom de la base
- l'IP à laquelle la commande `mysqldump` se connecte
- le nom du fichier `.tar.gz` ou `.zip` produit par le script

```bash
# Déclaration d'une variable toto qui contient la string "tata"
toto="tata"

# Appel de la variable toto
# Notez l'utilisation du dollar et des double quotes
echo "$toto"
```

```sh
# DONE :D
```

---

➜ **Commentez le script**

- au minimum un en-tête sous le shebang
  - date d'écriture du script
  - nom/pseudo de celui qui l'a écrit
  - un résumé TRES BREF de ce que fait le script

```sh
Done too 
```

---

➜ **Environnement d'exécution du script**

- créez un utilisateur sur la machine `db.tp2.linux`
  - il s'appellera `db_dumps`
  - son homedir sera `/srv/db_dumps/`
  - son shell sera `/usr/bin/nologin`
- cet utilisateur sera celui qui lancera le script
- le dossier `/srv/db_dumps/` doit appartenir au user `db_dumps`

```sh
[roxanne@db ~]$ sudo useradd db_dumps -m -d /srv/db_dumps -s /usr/bin/nologin
useradd: Warning: missing or non-executable shell '/usr/bin/nologin'
Creating mailbox file: File exists
```

```sh
[roxanne@db srv]$ ls -l
total 4
[...]
-rwxr--r--. 1 root     root     698 Nov 19 10:53 tp3_db_dump.sh
```

```sh
[roxanne@db srv]$ sudo chown db_dumps:db_dumps tp3_db_dump.sh
[roxanne@db srv]$ ls -l
total 4
[...]
-rwxr--r--. 1 db_dumps db_dumps 698 Nov 19 10:53 tp3_db_dump.sh
```

- pour tester l'exécution du script en tant que l'utilisateur `db_dumps`, utilisez la commande suivante :

```bash
$ sudo -u db_dumps /srv/tp3_db_dump.sh
```

```sh
[roxanne@db db_dumps]$ sudo -u db_dumps /srv/tp3_db_dump.sh
Backup started for database - nextcloud.
Backup successfully completed.
[roxanne@db db_dumps]$ ls -l
total 180
-rw-r--r--. 1 db_dumps db_dumps 152954 Nov 19 11:16 nextcloud_221119_111626.sql
-rw-r--r--. 1 db_dumps db_dumps  26729 Nov 19 11:18 nextcloud_221119_111840.sql.gz
```

```sh
# unzip de la sauvegarde
[roxanne@db db_dumps]$ sudo gzip -d nextcloud_221119_111840.sql.gz
[roxanne@db db_dumps]$ cat nextcloud_221119_111840.sql | head -8
-- MariaDB dump 10.19  Distrib 10.5.16-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: nextcloud
-- ------------------------------------------------------
-- Server version       10.5.16-MariaDB-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
```

---

✨ **Bonus : Ajoutez une gestion d'options au script**

- pour faire en sorte qu'on puisse choisir la valeur des variables déclarées dans le script depuis la ligne de commande
- utilisez [la commande `getopts`](https://www.quennec.fr/book/export/html/341) pour ce faire
- si des options sont manquantes à l'appel du script, alors une valeur par défaut sera utilisée
- on pourra par exemple exécuter votre script comme ça :

```bash
# On choisit la base 'nextcloud' à dump
$ ./tp3_db_dump.sh -D nextcloud
```

---

✨ **Bonus : Stocker le mot de passe pour se co à la base dans un fichier séparé**

- le fichier `/srv/db_pass` contiendra une unique ligne
- cette ligne sera une affectation de variable (juste `var=password`)
- dans le script `/srv/tp3_db_dump.sh`, utilisez une commande `source /srv/db_pass` pour récupérer cette variable

## III. Service et timer

➜ **Créez un *service*** système qui lance le script

- inspirez-vous du *service* créé à la fin du TP1
- la seule différence est que vous devez rajouter `Type=oneshot` dans la section `[Service]` pour indiquer au système que ce service ne tournera pas à l'infini (comme le fait un serveur web par exemple) mais se terminera au bout d'un moment
- vous appelerez le service `db-dump.service`
- assurez-vous qu'il fonctionne en utilisant des commandes `systemctl`

```sh
# création du service
[roxanne@db ~]$ cd /etc/systemd/system
[roxanne@db system]$ sudo nano db_dump.service
[sudo] password for roxanne:
[roxanne@db system]$ cat db_dump.service
[Unit]
Description=Dump the nextcloud database

[Service]
ExecStart=/srv/tp3_db_dump.sh
Type=oneshot
User=db_dumps
WorkingDirectory=/srv/db_dumps

[Install]
WantedBy=multi-user.target
```

```sh
# ajustement des permissions du script
[roxanne@db srv]$ sudo chmod 754 tp3_db_dump.sh
[roxanne@db srv]$ ls -l
total 4
drwxr-xr-x. 2 db_dumps db_dumps 132 Nov 19 11:19 db_dumps
-rwxr-xr--. 1 db_dumps db_dumps 699 Nov 19 11:15 tp3_db_dump.sh
```

```sh
# passage de Selinux en permissive :)
[roxanne@db srv]$ sudo nano /etc/selinux/config
```

```bash
$ sudo systemctl status db-dump
$ sudo systemctl start db-dump
```

```sh
[roxanne@db ~]$ sudo systemctl start db_dump
[roxanne@db ~]$ sudo systemctl status db_dump
○ db_dump.service - Dump the nextcloud database
     Loaded: loaded (/etc/systemd/system/db_dump.service; enabled; vendor preset: >
     Active: inactive (dead) since Sat 2022-11-19 12:05:02 CET; 1s ago
    Process: 1006 ExecStart=/srv/tp3_db_dump.sh (code=exited, status=0/SUCCESS)
   Main PID: 1006 (code=exited, status=0/SUCCESS)
        CPU: 43ms
```

➜ **Créez un *timer*** système qui lance le *service* à intervalles réguliers

- le fichier doit être créé dans le même dossier
- le fichier doit porter le même nom
- l'extension doit être `.timer` au lieu de `.service`
- ainsi votre fichier s'appellera `db-dump.timer`
- la syntaxe est la suivante :

```systemd
[Unit]
Description=Run service X

[Timer]
OnCalendar=*-*-* 4:00:00

[Install]
WantedBy=timers.target
```

> [La doc Arch est cool à ce sujet.](https://wiki.archlinux.org/title/systemd/Timers)

```sh
[roxanne@db system]$ sudo nano db_dump.timer
```

- une fois le fichier créé :

```bash
# demander au système de lire le contenu des dossiers de config
# il découvrira notre nouveau timer
$ sudo systemctl daemon-reload

# on peut désormais interagir avec le timer
$ sudo systemctl start db-dump.timer
$ sudo systemctl enable db-dump.timer
$ sudo systemctl status db-dump.timer

# il apparaîtra quand on demande au système de lister tous les timers
$ sudo systemctl list-timers
```

```sh
[roxanne@db system]$ sudo systemctl daemon-reload
[roxanne@db system]$ sudo systemctl start db_dump.timer
[roxanne@db system]$ sudo systemctl enable db_dump.timer
Created symlink /etc/systemd/system/timers.target.wants/db_dump.timer → /etc/systemd/system/db_dump.timer.
[roxanne@db system]$ sudo systemctl status db_dump.timer
● db_dump.timer - Run service db_dump
     Loaded: loaded (/etc/systemd/system/db_dump.timer; enabled; vendor preset: di>
     Active: active (waiting) since Sat 2022-11-19 12:08:48 CET; 16s ago
      Until: Sat 2022-11-19 12:08:48 CET; 16s ago
    Trigger: Sun 2022-11-20 04:00:00 CET; 15h left
   Triggers: ● db_dump.service

Nov 19 12:08:48 db.tp1.b2 systemd[1]: Started Run service db_dump.

[roxanne@db system]$ sudo systemctl status db_dump.timer
● db_dump.timer - Run service db_dump
     Loaded: loaded (/etc/systemd/system/db_dump.timer; enabled; vendor preset: di>
     Active: active (waiting) since Sat 2022-11-19 12:08:48 CET; 16s ago
      Until: Sat 2022-11-19 12:08:48 CET; 16s ago
    Trigger: Sun 2022-11-20 04:00:00 CET; 15h left
   Triggers: ● db_dump.service

Nov 19 12:08:48 db.tp1.b2 systemd[1]: Started Run service db_dump.

# le timer est bien présent dans la liste
[roxanne@db system]$ sudo systemctl list-timers
NEXT                        LEFT       LAST                        PASSED       UN>
Sat 2022-11-19 12:19:13 CET 8min left  n/a                         n/a          sy>
Sat 2022-11-19 12:22:00 CET 11min left n/a                         n/a          dn>
Sun 2022-11-20 00:00:00 CET 11h left   Sat 2022-11-19 10:15:34 CET 1h 55min ago lo>
Sun 2022-11-20 04:00:00 CET 15h left   n/a                         n/a          db>

4 timers listed.
Pass --all to see loaded but inactive timers, too.
```

➜ **Tester la restauration des données** sinon ça sert à rien :)

- livrez-moi la suite de commande que vous utiliseriez pour restaurer les données dans une version antérieure

```sh
sudo gzip -d 'nom_du_fichier.sql.gz'
cat 'nom_du_fichier.sql'
```
