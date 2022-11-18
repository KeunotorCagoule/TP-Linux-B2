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
[roxanne@db srv]$ cat tp3_db_dump.sh
#!/bin/bash
# Last Update : 18/11/2022
# Written by : Roulland Roxanne
# This script will dump the database and save it to a file

# Set the variables
user='restore'
passwd='toto'
db='nextcloud'
ip_serv='10.102.1.12'
datelog=$(date '+[%y/%m/%d %T]')
datesauv=$(date '+%y%m%d_%H%M%S')
name=nextcloud_'$datesauv'
backuppath='/srv/db_dumps'

# Dump the database
if [["$(id -u)" = "0"]]
then
        mkdir -p ${backuppath}
        echo "Backup started for database - ${db}."
        mysqldump -h ${ip_serv} -u ${user} -p${passwd} ${db} | gzip &get; ${backuppath}/${name}
        if [$? -eq 0]; then
                echo "Backup successfully completed."
        else
                echo "Backup failed."
                exit 1
        fi
else
        echo "You must be root to run this script"
        exit 1
fi
```

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

- pour tester l'exécution du script en tant que l'utilisateur `db_dumps`, utilisez la commande suivante :

```bash
$ sudo -u db_dumps /srv/tp3_db_dump.sh
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

```bash
$ sudo systemctl status db-dump
$ sudo systemctl start db-dump
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

➜ **Tester la restauration des données** sinon ça sert à rien :)

- livrez-moi la suite de commande que vous utiliseriez pour restaurer les données dans une version antérieure
