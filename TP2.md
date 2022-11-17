# TP2 : Gestion de service

Dans ce TP on va s'orienter sur l'**utilisation des systèmes GNU/Linux** comme un outil pour **faire tourner des services**. C'est le principal travail de l'administrateur système : fournir des services.

Ces services, on fait toujours la même chose avec :

- **installation** (opération ponctuelle)
- **configuration** (opération ponctuelle)
- **maintien en condition opérationnelle** (opération continue, tant que le service est actif)
- **renforcement niveau sécurité** (opération ponctuelle et continue : on conf robuste et on se tient à jour)

**Dans cette première partie, on va voir la partie installation et configuration.** Peu importe l'outil visé, de la base de données au serveur cache, en passant par le serveur web, le serveur mail, le serveur DNS, ou le serveur privé de ton meilleur jeu en ligne, c'est toujours pareil : install into conf.

On abordera la sécurité et le maintien en condition opérationelle dans une deuxième partie.

**On va apprendre à maîtriser un peu ces étapes, et pas simplement suivre la doc.**

On va maîtriser le service fourni :

- manipulation du service avec systemd
- quelle IP et quel port il utilise
- quels utilisateurs du système sont mobilisés
- quels processus sont actifs sur la machine pour que le service soit actif
- gestion des fichiers qui concernent le service et des permissions associées
- gestion avancée de la configuration du service

---

Bon le service qu'on va setup c'est NextCloud. **JE SAIS** ça fait redite avec l'an dernier, me tapez pas. ME TAPEZ PAS.  

Mais vous inquiétez pas, on va pousser le truc, on va faire évoluer l'install, l'architecture de la solution. Cette première partie de TP, on réalise une install basique, simple, simple, basique, la version *vanilla* un peu. Ce que vous êtes censés commencer à maîtriser (un peu, faites moi plais).

Refaire une install guidée, ça permet de s'exercer à faire ça proprement dans un cadre, bien comprendre, et ça me fait un pont pour les B1C aussi :)

On va faire évoluer la solution dans la suite de ce TP.

# Sommaire

- [TP2 : Gestion de service](#tp2--gestion-de-service)
- [Sommaire](#sommaire)
- [0. Prérequis](#0-prérequis)
  - [Checklist](#checklist)
- [I. Un premier serveur web](#i-un-premier-serveur-web)
  - [1. Installation](#1-installation)
  - [2. Avancer vers la maîtrise du service](#2-avancer-vers-la-maîtrise-du-service)
- [II. Une stack web plus avancée](#ii-une-stack-web-plus-avancée)
  - [1. Intro blabla](#1-intro-blabla)
  - [2. Setup](#2-setup)
    - [A. Base de données](#a-base-de-données)
    - [B. Serveur Web et NextCloud](#b-serveur-web-et-nextcloud)
    - [C. Finaliser l'installation de NextCloud](#c-finaliser-linstallation-de-nextcloud)

# 0. Prérequis

➜ Machines Rocky Linux

➜ Un unique host-only côté VBox, ça suffira. **L'adresse du réseau host-only sera `10.102.1.0/24`.**

➜ Chaque **création de machines** sera indiquée par **l'emoji 🖥️ suivi du nom de la machine**

➜ Si je veux **un fichier dans le rendu**, il y aura l'**emoji 📁 avec le nom du fichier voulu**. Le fichier devra être livré tel quel dans le dépôt git, ou dans le corps du rendu Markdown si c'est lisible et correctement formaté.

## Checklist

A chaque machine déployée, vous **DEVREZ** vérifier la 📝**checklist**📝 :

- [x] IP locale, statique ou dynamique
- [x] hostname défini
- [x] firewall actif, qui ne laisse passer que le strict nécessaire
- [x] SSH fonctionnel avec un échange de clé
- [x] accès Internet (une route par défaut, une carte NAT c'est très bien)
- [x] résolution de nom
- [x] SELinux désactivé (vérifiez avec `sestatus`, voir [mémo install VM tout en bas](https://gitlab.com/it4lik/b2-reseau-2022/-/blob/main/cours/memo/install_vm.md#4-pr%C3%A9parer-la-vm-au-clonage))

**Les éléments de la 📝checklist📝 sont STRICTEMENT OBLIGATOIRES à réaliser mais ne doivent PAS figurer dans le rendu.**

![Checklist](./pics/checklist_is_here.jpg)

# I. Un premier serveur web

## 1. Installation

🖥️ **VM web.tp2.linux**

| Machine         | IP            | Service     |
|-----------------|---------------|-------------|
| `web.tp2.linux` | `10.102.1.11` | Serveur Web |

🌞 **Installer le serveur Apache**

- paquet `httpd`
- la conf se trouve dans `/etc/httpd/`
  - le fichier de conf principal est `/etc/httpd/conf/httpd.conf`
  - je vous conseille **vivement** de virer tous les commentaire du fichier, à défaut de les lire, vous y verrez plus clair
    - avec `vim` vous pouvez tout virer avec `:g/^ *#.*/d

```bash
[roxanne@web ~]$ sudo dnf install httpd
Rocky Linux 9 - BaseOS                      6.3 kB/s | 3.6 kB     00:00
Rocky Linux 9 - AppStream                   679  B/s | 3.6 kB     00:05
Rocky Linux 9 - Extras                      6.6 kB/s | 2.9 kB     00:00
Dependencies resolved.
[...]
```

```bash
# édition du fichier pour enlever les commentaires
[roxanne@web ~]$ sudo vim /etc/httpd/conf/httpd.conf
[roxanne@web ~]$ cat /etc/httpd/conf/httpd.conf

ServerRoot "/etc/httpd"

Listen 80

Include conf.modules.d/*.conf

User apache
Group apache
[...]
```

> Ce que j'entends au-dessus par "fichier de conf principal" c'est que c'est **LE SEUL** fichier de conf lu par Apache quand il démarre. C'est souvent comme ça : un service ne lit qu'un unique fichier de conf pour démarrer. Cherchez pas, on va toujours au plus simple. Un seul fichier, c'est simple.  
**En revanche** ce serait le bordel si on mettait toute la conf dans un seul fichier pour pas mal de services.  
Donc, le principe, c'est que ce "fichier de conf principal" définit généralement deux choses. D'une part la conf globale. D'autre part, il inclut d'autres fichiers de confs plus spécifiques.  
On a le meilleur des deux mondes : simplicité (un seul fichier lu au démarrage) et la propreté (éclater la conf dans plusieurs fichiers).

🌞 **Démarrer le service Apache**

- le service s'appelle `httpd` (raccourci pour `httpd.service` en réalité)
  - démarrez le
  - faites en sorte qu'Apache démarre automatique au démarrage de la machine
  - ouvrez le port firewall nécessaire
    - utiliser une commande `ss` pour savoir sur quel port tourne actuellement Apache
    - [une petite portion du mémo est consacrée à `ss`](https://gitlab.com/it4lik/b2-linux-2021/-/blob/main/cours/memo/commandes.md#r%C3%A9seau)

```bash
# lancement du service httpd
[roxanne@web ~]$ sudo systemctl start httpd
[roxanne@web ~]$ sudo systemctl enable httpd
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
[roxanne@web ~]$ sudo systemctl status httpd
● httpd.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled; vendo>
     Active: active (running) since Tue 2022-11-15 10:19:47 CET; 5s ago
       Docs: man:httpd.service(8)
   Main PID: 1274 (httpd)
     Status: "Started, listening on: port 80"
      Tasks: 213 (limit: 5896)
     Memory: 27.5M
        CPU: 64ms
     CGroup: /system.slice/httpd.service
             ├─1274 /usr/sbin/httpd -DFOREGROUND
             ├─1275 /usr/sbin/httpd -DFOREGROUND
             ├─1276 /usr/sbin/httpd -DFOREGROUND
             ├─1277 /usr/sbin/httpd -DFOREGROUND
             └─1278 /usr/sbin/httpd -DFOREGROUND

Nov 15 10:19:46 web.tp2.linux systemd[1]: Starting The Apache HTTP Server...
Nov 15 10:19:47 web.tp2.linux systemd[1]: Started The Apache HTTP Server.
```

```bash
# ouverture du port 80 pour httpd
[roxanne@web ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success
[roxanne@web ~]$ sudo firewall-cmd --reload
success
```

```bash
# apache écoute sur le port 80
[roxanne@web ~]$ sudo ss -laptn | grep httpd
LISTEN 0      511                *:80              *:*    users:(("httpd",pid=1278,fd=4),("httpd",pid=1277,fd=4),("httpd",pid=1276,fd=4),("httpd",pid=1274,fd=4))
```

**En cas de problème** (IN CASE OF FIIIIRE) vous pouvez check les logs d'Apache :

```bash
# Demander à systemd les logs relatifs au service httpd
$ sudo journalctl -xe -u httpd

# Consulter le fichier de logs d'erreur d'Apache
$ sudo cat /var/log/httpd/error_log

# Il existe aussi un fichier de log qui enregistre toutes les requêtes effectuées sur votre serveur
$ sudo cat /var/log/httpd/access_log
```

🌞 **TEST**

- vérifier que le service est démarré

```bash
# vérification
[roxanne@web ~]$ systemctl status httpd
● httpd.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled; vendo>
     Active: active (running) since Tue 2022-11-15 10:19:47 CET; 9min ago
       Docs: man:httpd.service(8)
   Main PID: 1274 (httpd)
     Status: "Total requests: 0; Idle/Busy workers 100/0;Requests/sec: 0; B>
      Tasks: 213 (limit: 5896)
     Memory: 27.5M
        CPU: 343ms
     CGroup: /system.slice/httpd.service
             ├─1274 /usr/sbin/httpd -DFOREGROUND
             ├─1275 /usr/sbin/httpd -DFOREGROUND
             ├─1276 /usr/sbin/httpd -DFOREGROUND
             ├─1277 /usr/sbin/httpd -DFOREGROUND
             └─1278 /usr/sbin/httpd -DFOREGROUND
    [...]
```

- vérifier qu'il est configuré pour démarrer automatiquement

```bash
[roxanne@web ~]$ systemctl is-enabled httpd
enabled
```

- vérifier avec une commande `curl localhost` que vous joignez votre serveur web localement

```bash
# vérification de l'accessibilité du serveur web
[roxanne@web ~]$ curl localhost
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/

      html {
        height: 100%;
        width: 100%;
      }
[...]
```

- vérifier avec votre navigateur (sur votre PC) que vous accéder à votre serveur web

```bash
  ~    curl 10.102.1.11:80
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/

      html {
        height: 100%;
        width: 100%;
      }
```

## 2. Avancer vers la maîtrise du service

🌞 **Le service Apache...**

- affichez le contenu du fichier `httpd.service` qui contient la définition du service Apache

```bash
[roxanne@web ~]$ sudo cat /etc/systemd/system/multi-user.target.wants/httpd.service
[sudo] password for roxanne:
[# See httpd.service(8) for more information on using the httpd service.

# Modifying this file in-place is not recommended, because changes
# will be overwritten during package upgrades.  To customize the
# behaviour, run "systemctl edit httpd" to create an override unit.

# For example, to pass additional options (such as -D definitions) to
# the httpd binary at startup, create an override unit (as is done by
# systemctl edit) and enter the following:

#       [Service]
#       Environment=OPTIONS=-DMY_DEFINE
]
[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpd-init.service
Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C

ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true
OOMPolicy=continue

[Install]
WantedBy=multi-user.target
```

🌞 **Déterminer sous quel utilisateur tourne le processus Apache**

- mettez en évidence la ligne dans le fichier de conf principal d'Apache (`httpd.conf`) qui définit quel user est utilisé

```bash
[roxanne@web conf]$ cat httpd.conf | grep User
User apache
[...]
```

- utilisez la commande `ps -ef` pour visualiser les processus en cours d'exécution et confirmer que apache tourne bien sous l'utilisateur mentionné dans le fichier de conf

```bash
# vérification de l'utilisateur qui éxecute apache
[roxanne@web conf]$ sudo ps -ef | grep apache
apache      1275    1274  0 10:19 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      1276    1274  0 10:19 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      1277    1274  0 10:19 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      1278    1274  0 10:19 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
```

- la page d'accueil d'Apache se trouve dans `/usr/share/testpage/`
  - vérifiez avec un `ls -al` que tout son contenu est **accessible en lecture** à l'utilisateur mentionné dans le fichier de conf

```bash
# le dossier appartient à root est accessible en lecture par apache
[roxanne@web testpage]$ ls -al
total 12
drwxr-xr-x.  2 root root   24 Nov 15 09:51 .
drwxr-xr-x. 82 root root 4096 Nov 15 10:14 ..
-rw-r--r--.  1 root root 7620 Jul  6 04:37 index.html
```

🌞 **Changer l'utilisateur utilisé par Apache**

- créez un nouvel utilisateur
  - pour les options de création, inspirez-vous de l'utilisateur Apache existant
    - le fichier `/etc/passwd` contient les informations relatives aux utilisateurs existants sur la machine
    - servez-vous en pour voir la config actuelle de l'utilisateur Apache par défaut

```bash
# création d'un nouvel utilisateur
[roxanne@web ~]$ sudo useradd web -m -d /usr/share/httpd -s /bin/bash
useradd: warning: the home directory /usr/share/httpd already exists.
useradd: Not copying any file from skel directory into it.
Creating mailbox file: File exists
```

- modifiez la configuration d'Apache pour qu'il utilise ce nouvel utilisateur

```bash
# modification du fichier de conf pour utiliser le nouvel utilisateur
[roxanne@web conf]$ sudo nano httpd.conf
[roxanne@web conf]$ cat httpd.conf | head -10

ServerRoot "/etc/httpd"

Listen 80

Include conf.modules.d/*.conf

User web
Group web
```

- redémarrez Apache

```bash
# redémarrage du service apache et vérification
[roxanne@web conf]$ sudo systemctl restart httpd
[roxanne@web conf]$ systemctl status httpd
● httpd.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor>
     Active: active (running) since Tue 2022-11-15 11:07:08 CET; 11s ago
       Docs: man:httpd.service(8)
   Main PID: 1682 (httpd)
   [...]
```

- utilisez une commande `ps` pour vérifier que le changement a pris effet

```bash
[roxanne@web conf]$ sudo ps -ef | grep web
web         1683    1682  0 11:07 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
web         1684    1682  0 11:07 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
web         1685    1682  0 11:07 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
web         1686    1682  0 11:07 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
```

🌞 **Faites en sorte que Apache tourne sur un autre port**

- modifiez la configuration d'Apache pour lui demander d'écouter sur un autre port de votre choix

```bash
[roxanne@web conf]$ sudo nano httpd.conf
[roxanne@web conf]$ cat httpd.conf | head -5

ServerRoot "/etc/httpd"

Listen 8080
```

- ouvrez ce nouveau port dans le firewall, et fermez l'ancien

```bash
[roxanne@web conf]$ sudo firewall-cmd --remove-port=80/tcp
success
[roxanne@web conf]$ sudo firewall-cmd --add-port=8080/tcp --permanent
success
[roxanne@web conf]$ sudo firewall-cmd --reload
success
```

- redémarrez Apache

```sh
[roxanne@web conf]$ sudo systemctl restart httpd
```

- prouvez avec une commande `ss` que Apache tourne bien sur le nouveau port choisi

```sh
# apache tourne bien sur le nouveau port
[roxanne@web conf]$ sudo ss -laptn | grep httpd
LISTEN 0      511                *:8080            *:*    users:(("httpd",pid=1948,fd=4),("httpd",pid=1947,fd=4),("httpd",pid=1946,fd=4),("httpd",pid=1943,fd=4))
```

- vérifiez avec `curl` en local que vous pouvez joindre Apache sur le nouveau port

```sh
[roxanne@web conf]$ curl localhost:8080
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/

      html {
        height: 100%;
        width: 100%;
      }
```

- vérifiez avec votre navigateur que vous pouvez joindre le serveur sur le nouveau port

```sh
  ~    curl 10.102.1.11:8080
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/

      html {
        height: 100%;
        width: 100%;
      }
```

📁 **Fichier `/etc/httpd/conf/httpd.conf`** --> [Lien](httpd.conf)

# II. Une stack web plus avancée

⚠⚠⚠ **Réinitialiser votre conf Apache avant de continuer** ⚠⚠⚠  
En particulier :

- reprendre le port par défaut
- reprendre l'utilisateur par défaut

```sh
Done
```

## 1. Intro blabla

**Le serveur web `web.tp2.linux` sera le serveur qui accueillera les clients.** C'est sur son IP que les clients devront aller pour visiter le site web.  

**Le service de base de données `db.tp2.linux` sera uniquement accessible depuis `web.tp2.linux`.** Les clients ne pourront pas y accéder. Le serveur de base de données stocke les infos nécessaires au serveur web, pour le bon fonctionnement du site web.

---

Bon le but de ce TP est juste de s'exercer à faire tourner des services, un serveur + sa base de données, c'est un peu le cas d'école. J'ai pas envie d'aller deep dans la conf de l'un ou de l'autre avec vous pour le moment, on va se contenter d'une conf minimale.

Je vais pas vous demander de coder une application, et cette fois on se contentera pas d'un simple `index.html` tout moche et on va se mettre dans la peau de l'admin qui se retrouve avec une application à faire tourner. **On va faire tourner un [NextCloud](https://nextcloud.com/).**

En plus c'est utile comme truc : c'est un p'tit serveur pour héberger ses fichiers via une WebUI, style Google Drive. Mais on l'héberge nous-mêmes :)

---

Le flow va être le suivant :

➜ **on prépare d'abord la base de données**, avant de setup NextCloud

- comme ça il aura plus qu'à s'y connecter
- ce sera sur une nouvelle machine `db.tp2.linux`
- il faudra installer le service de base de données, puis lancer le service
- on pourra alors créer, au sein du service de base de données, le nécessaire pour NextCloud

➜ **ensuite on met en place NextCloud**

- on réutilise la machine précédente avec Apache déjà installé, ce sera toujours Apache qui accueillera les requêtes des clients
- mais plutôt que de retourner une bête page HTML, NextCloud traitera la requête
- NextCloud, c'est codé en PHP, il faudra donc **installer une version de PHP précise** sur la machine
- on va donc : install PHP, configurer Apache, récupérer un `.zip` de NextCloud, et l'extraire au bon endroit !

![NextCloud install](./pics/nc_install.png)

## 2. Setup

🖥️ **VM db.tp2.linux**

**N'oubliez pas de dérouler la [📝**checklist**📝](#checklist).**

| Machines        | IP            | Service                 |
|-----------------|---------------|-------------------------|
| `web.tp2.linux` | `10.102.1.11` | Serveur Web             |
| `db.tp2.linux`  | `10.102.1.12` | Serveur Base de Données |

### A. Base de données

🌞 **Install de MariaDB sur `db.tp2.linux`**

- déroulez [la doc d'install de Rocky](https://docs.rockylinux.org/guides/database/database_mariadb-server/)
- je veux dans le rendu **toutes** les commandes réalisées

```sh
# installation de mariadb
[roxanne@db ~]$ sudo dnf install mariadb-server
[sudo] password for roxanne:
Rocky Linux 9 - BaseOS                      8.2 kB/s | 3.6 kB     00:00
Rocky Linux 9 - BaseOS                      2.1 MB/s | 1.7 MB     00:00
[...]
```

```sh
# lancement de mariadb
[roxanne@db ~]$ sudo systemctl enable mariadb
Created symlink /etc/systemd/system/mysql.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/mysqld.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/multi-user.target.wants/mariadb.service → /usr/lib/systemd/system/mariadb.service.
[roxanne@db ~]$ sudo systemctl start mariadb
```

```sh
[roxanne@db ~]$ sudo mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

[...]

Thanks for using MariaDB!
```

- vous repérerez le port utilisé par MariaDB avec une commande `ss` exécutée sur `db.tp2.linux`
  - il sera nécessaire de l'ouvrir dans le firewall

> La doc vous fait exécuter la commande `mysql_secure_installation` c'est un bon réflexe pour renforcer la base qui a une configuration un peu *chillax* à l'install.

🌞 **Préparation de la base pour NextCloud**

- une fois en place, il va falloir préparer une base de données pour NextCloud :
  - connectez-vous à la base de données à l'aide de la commande `sudo mysql -u root -p`
  - exécutez les commandes SQL suivantes :

```sql
# Création d'un utilisateur dans la base, avec un mot de passe
# L'adresse IP correspond à l'adresse IP depuis laquelle viendra les connexions. Cela permet de restreindre les IPs autorisées à se connecter.
# Dans notre cas, c'est l'IP de web.tp2.linux
# "pewpewpew" c'est le mot de passe hehe
CREATE USER 'nextcloud'@'10.102.1.11' IDENTIFIED BY 'pewpewpew';

# Création de la base de donnée qui sera utilisée par NextCloud
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

# On donne tous les droits à l'utilisateur nextcloud sur toutes les tables de la base qu'on vient de créer
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.102.1.11';

# Actualisation des privilèges
FLUSH PRIVILEGES;

# C'est assez générique comme opération, on crée une base, on crée un user, on donne les droits au user sur la base
```

```sql
# création du user
MariaDB [(none)]> CREATE USER 'nextcloud'@'10.102.1.11' IDENTIFIED BY 'toto';
Query OK, 0 rows affected (0.002 sec)

# création de la base
MariaDB [(none)]> CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
Query OK, 1 row affected (0.000 sec)

# on donne tous les droits à l'utilisateur nextcloud sur toutes les tables de la base qu'on vient de créer
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.102.1.11';
Query OK, 0 rows affected (0.008 sec)

# Actualisation des privilèges
MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.000 sec)
```

> Par défaut, vous avez le droit de vous connecter localement à la base si vous êtes `root`. C'est pour ça que `sudo mysql -u root` fonctionne, sans nous demander de mot de passe. Evidemment, n'importe quelles autres conditions ne permettent pas une connexion aussi facile à la base.

🌞 **Exploration de la base de données**

- afin de tester le bon fonctionnement de la base de données, vous allez essayer de vous connecter, comme NextCloud le fera :
  - depuis la machine `web.tp2.linux` vers l'IP de `db.tp2.linux`
  - utilisez la commande `mysql` pour vous connecter à une base de données depuis la ligne de commande
    - par exemple `mysql -u <USER> -h <IP_DATABASE> -p`
    - si vous ne l'avez pas, installez-là
    - vous pouvez déterminer dans quel paquet est disponible la commande `mysql` en saisissant `dnf provides mysql`

```sh
[roxanne@web conf]$ sudo dnf install mysql
[sudo] password for roxanne:
Last metadata expiration check: 2:07:08 ago on Tue 15 Nov 2022 10:00:44 CET.
Dependencies resolved.
```

```sh
# ouverture du port de Mariadb sur la machien db.tp2.linux
[roxanne@db ~]$ sudo firewall-cmd --add-port=3306/tcp --permanent
success
[roxanne@db ~]$ sudo firewall-cmd --reload
success
```

```sql
mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
2 rows in set (0.00 sec)

mysql> USE nextcloud;
Database changed
mysql> SHOW TABLES;
Empty set (0.00 sec)
```

- **donc vous devez effectuer une commande `mysql` sur `web.tp2.linux`**
- une fois connecté à la base, utilisez les commandes SQL fournies ci-dessous pour explorer la base

```sql
SHOW DATABASES;
USE <DATABASE_NAME>;
SHOW TABLES;
```

🌞 **Trouver une commande SQL qui permet de lister tous les utilisateurs de la base de données**

> Les utilisateurs de la base de données sont différents des utilisateurs du système Rocky Linux qui porte la base. Les utilisateurs de la base définissent des identifiants utilisés pour se connecter à la base afin d'y voir ou d'y modifier des données.

Une fois qu'on s'est assurés qu'on peut se co au service de base de données depuis `web.tp2.linux`, on peut continuer.

```sql
[roxanne@db ~]$ sudo mysql -u root -p
[...]

MariaDB [(none)]> SELECT user FROM mysql.user;
+-------------+
| User        |
+-------------+
| nextcloud   |
| mariadb.sys |
| mysql       |
| root        |
+-------------+
4 rows in set (0.001 sec)
```

### B. Serveur Web et NextCloud

⚠️⚠️⚠️ **N'OUBLIEZ PAS de réinitialiser votre conf Apache avant de continuer. En particulier, remettez le port et le user par défaut.**

🌞 **Install de PHP**

```bash
# On ajoute le dépôt CRB
$ sudo dnf config-manager --set-enabled crb
# On ajoute le dépôt REMI
$ sudo dnf install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm -y

# On liste les versions de PHP dispos, au passage on va pouvoir accepter les clés du dépôt REMI
$ dnf module list php

# On active le dépôt REMI pour récupérer une version spécifique de PHP, celle recommandée par la doc de NextCloud
$ sudo dnf module enable php:remi-8.1 -y

# Eeeet enfin, on installe la bonne version de PHP : 8.1
$ sudo dnf install -y php81-php
```

```sh
# installation de php sur la machine web
[roxanne@web ~]$ sudo dnf config-manager --set-enabled crb
[sudo] password for roxanne:
[roxanne@web ~]$ sudo dnf install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
Rocky Linux 9 - BaseOS                      7.3 kB/s | 3.6 kB     00:00
Rocky Linux 9 - AppStream                   6.4 kB/s | 3.6 kB     00:00
Rocky Linux 9 - CRB                         2.0 MB/s | 1.9 MB     00:00
remi-release-9.rpm                          172 kB/s |  25 kB     00:00
Dependencies resolved.
[...]

Complete!

[roxanne@web ~]$ dnf module list php
Extra Packages for Enterprise Linux 9 - x86 3.0 MB/s |  11 MB     00:03
Remi's Modular repository for Enterprise Li 1.9 kB/s | 833  B     00:00
Remi's Modular repository for Enterprise Li 3.0 MB/s | 3.1 kB     00:00
[...]

[roxanne@web ~]$ sudo dnf module enable php:remi-8.1 -y
[sudo] password for roxanne:
Extra Packages for Enterprise Linux 9 - x86 3.7 MB/s |  11 MB     00:03
Remi's Modular repository for Enterprise Li 1.9 kB/s | 833  B     00:00
Remi's Modular repository for Enterprise Li 3.0 MB/s | 3.1 kB     00:00
[...]

[roxanne@web ~]$ sudo dnf install -y php81-php
Last metadata expiration check: 0:01:37 ago on Tue 15 Nov 2022 12:37:36 CET.
Dependencies resolved.
[...]
```

🌞 **Install de tous les modules PHP nécessaires pour NextCloud**

```bash
# eeeeet euuuh boom. Là non plus j'ai pas pondu ça, c'est la doc :
$ sudo dnf install -y libxml2 openssl php81-php php81-php-ctype php81-php-curl php81-php-gd php81-php-iconv php81-php-json php81-php-libxml php81-php-mbstring php81-php-openssl php81-php-posix php81-php-session php81-php-xml php81-php-zip php81-php-zlib php81-php-pdo php81-php-mysqlnd php81-php-intl php81-php-bcmath php81-php-gmp
```

```sh
[roxanne@web ~]$ sudo dnf install -y libxml2 openssl php81-php php81-php-ctype php81-php-curl php81-php-gd php81-php-iconv php81-php-json php81-php-libxml php81-php-mbstring php81-php-openssl php81-php-posix php81-php-session php81-php-xml php81-php-zip php81-php-zlib php81-php-pdo php81-php-mysqlnd php81-php-intl php81-php-bcmath php81-php-gmp
Last metadata expiration check: 0:02:37 ago on Tue 15 Nov 2022 12:37:36 CET.
Package libxml2-2.9.13-1.el9.x86_64 is already installed.
Package openssl-1:3.0.1-20.el9_0.x86_64 is already installed.
Package php81-php-8.1.12-1.el9.remi.x86_64 is already installed.
[...]
```

🌞 **Récupérer NextCloud**

- créez le dossier `/var/www/tp2_nextcloud/`
  - ce sera notre *racine web* (ou *webroot*)
  - l'endroit où le site est stocké quoi, on y trouvera un `index.html` et un tas d'autres marde, tout ce qui constitue NextClo :D

```sh
# création du dossier
[roxanne@web ~]$ cd /var/www/
[roxanne@web www]$ ls
cgi-bin  html
[roxanne@web www]$ sudo mkdir tp2_nextcloud
[roxanne@web www]$ ls
cgi-bin  html  tp2_nextcloud
```

- récupérer le fichier suivant avec une commande `curl` ou `wget` : https://download.nextcloud.com/server/prereleases/nextcloud-25.0.0rc3.zip
- extrayez tout son contenu dans le dossier `/var/www/tp2_nextcloud/` en utilisant la commande `unzip`
  - installez la commande `unzip` si nécessaire
  - vous pouvez extraire puis déplacer ensuite, vous prenez pas la tête
  - contrôlez que le fichier `/var/www/tp2_nextcloud/index.html` existe pour vérifier que tout est en place
- assurez-vous que le dossier `/var/www/tp2_nextcloud/` et tout son contenu appartient à l'utilisateur qui exécute le service Apache

```sh
# installation de unzip
[roxanne@web tp2_nextcloud]$ sudo dnf install unzip -y
Last metadata expiration check: 0:11:22 ago on Tue 15 Nov 2022 12:37:36 CET.
Dependencies resolved.
```

```sh
# récupération du fichier
[roxanne@web tp2_nextcloud]$ sudo curl https://download.nextcloud.com/server/prereleases/nextcloud-25.0.0rc3.zip --output nextcloud.zip

# extraction du fichier
[roxanne@web tp2_nextcloud]$ sudo unzip nextcloud.zip

# déplacement des fichiers
[roxanne@web nextcloud]$ sudo mv * /var/www/tp2_nextcloud/
[roxanne@web tp2_nextcloud]$ ls
3rdparty     core        nextcloud      public.php  updater
apps         cron.php    nextcloud.zip  remote.php  version.php
AUTHORS      dist        occ            resources
config       index.html  ocm-provider   robots.txt
console.php  index.php   ocs            status.php
COPYING      lib         ocs-provider   themes

# supression du fichier zip et du dossier vide
[roxanne@web tp2_nextcloud]$ sudo rm -rf nextcloud
[roxanne@web tp2_nextcloud]$ sudo rm nextcloud.zip
[roxanne@web tp2_nextcloud]$ ls
3rdparty  console.php  dist        occ           public.php  status.php
apps      COPYING      index.html  ocm-provider  remote.php  themes
AUTHORS   core         index.php   ocs           resources   updater
config    cron.php     lib         ocs-provider  robots.txt  version.php

# verification de l'existence d'index.html
[roxanne@web tp2_nextcloud]$ ls | grep index.html
index.html
```

> A chaque fois que vous faites ce genre de trucs, assurez-vous que c'est bien ok. Par exemple, vérifiez avec un `ls -al` que tout appartient bien à l'utilisateur qui exécute Apache.

```sh
# vérification de l'appartenance des fichiers
[roxanne@web www]$ sudo chown -R apache:apache tp2_nextcloud/
[roxanne@web www]$ ls -al
total 8
drwxr-xr-x.  5 root   root     54 Nov 15 12:44 .
drwxr-xr-x. 20 root   root   4096 Nov 15 09:51 ..
drwxr-xr-x.  2 root   root      6 May 16  2022 cgi-bin
drwxr-xr-x.  2 root   root      6 May 16  2022 html
drwxr-xr-x. 14 apache apache 4096 Nov 15 12:54 tp2_nextcloud

[roxanne@web www]$ cd tp2_nextcloud/
[roxanne@web tp2_nextcloud]$ ls -al
total 132
drwxr-xr-x. 14 apache apache  4096 Nov 15 12:54 .
drwxr-xr-x.  5 root   root      54 Nov 15 12:44 ..
drwxr-xr-x. 47 apache apache  4096 Oct  6 14:47 3rdparty
drwxr-xr-x. 50 apache apache  4096 Oct  6 14:44 apps
-rw-r--r--.  1 apache apache 19327 Oct  6 14:42 AUTHORS
drwxr-xr-x.  2 apache apache    67 Oct  6 14:47 config
-rw-r--r--.  1 apache apache  4095 Oct  6 14:42 console.php
-rw-r--r--.  1 apache apache 34520 Oct  6 14:42 COPYING
drwxr-xr-x. 23 apache apache  4096 Oct  6 14:47 core
-rw-r--r--.  1 apache apache  6317 Oct  6 14:42 cron.php
drwxr-xr-x.  2 apache apache  8192 Oct  6 14:42 dist
-rw-r--r--.  1 apache apache   156 Oct  6 14:42 index.html
-rw-r--r--.  1 apache apache  3456 Oct  6 14:42 index.php
drwxr-xr-x.  6 apache apache   125 Oct  6 14:42 lib
-rw-r--r--.  1 apache apache   283 Oct  6 14:42 occ
drwxr-xr-x.  2 apache apache    23 Oct  6 14:42 ocm-provider
drwxr-xr-x.  2 apache apache    55 Oct  6 14:42 ocs
drwxr-xr-x.  2 apache apache    23 Oct  6 14:42 ocs-provider
-rw-r--r--.  1 apache apache  3139 Oct  6 14:42 public.php
-rw-r--r--.  1 apache apache  5426 Oct  6 14:42 remote.php
drwxr-xr-x.  4 apache apache   133 Oct  6 14:42 resources
-rw-r--r--.  1 apache apache    26 Oct  6 14:42 robots.txt
-rw-r--r--.  1 apache apache  2452 Oct  6 14:42 status.php
drwxr-xr-x.  3 apache apache    35 Oct  6 14:42 themes
drwxr-xr-x.  2 apache apache    43 Oct  6 14:44 updater
-rw-r--r--.  1 apache apache   387 Oct  6 14:47 version.php
```

🌞 **Adapter la configuration d'Apache**

- regardez la dernière ligne du fichier de conf d'Apache pour constater qu'il existe une ligne qui inclut d'autres fichiers de conf
- créez en conséquence un fichier de configuration qui porte un nom clair et qui contient la configuration suivante :

```apache
<VirtualHost *:80>
  DocumentRoot /var/www/tp2_nextcloud/ # on indique le chemin de notre webroot
  ServerName  web.tp2.linux # on précise le nom que saisissent les clients pour accéder au service
  <Directory /var/www/tp2_nextcloud/> # on définit des règles d'accès sur notre webroot
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
```

```sh
# vérification du fichier de conf pour savoir comment créer le fichier de conf supplémentaire
[roxanne@web ~]$ sudo cat /etc/httpd/conf/httpd.conf

# création du fichier de conf supplémentaire
[roxanne@web ~]$ sudo nano /etc/httpd/conf.d/nextcloud.conf
[roxanne@web ~]$ cat /etc/httpd/conf.d/nextcloud.conf
<VirtualHost *:80>
  DocumentRoot /var/www/tp2_nextcloud/
  ServerName  web.tp2.linux
  <Directory /var/www/tp2_nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
```

🌞 **Redémarrer le service Apache** pour qu'il prenne en compte le nouveau fichier de conf

```sh
[roxanne@web ~]$ sudo systemctl restart httpd
```

### C. Finaliser l'installation de NextCloud

➜ **Sur votre PC**

- modifiez votre fichier `hosts` (oui, celui de votre PC, de votre hôte)
  - pour pouvoir joindre l'IP de la VM en utilisant le nom `web.tp2.linux`
- avec un navigateur, visitez NextCloud à l'URL `http://web.tp2.linux`
  - c'est possible grâce à la modification de votre fichier `hosts`
- on va vous demander un utilisateur et un mot de passe pour créer un compte admin
  - ne saisissez rien pour le moment
- cliquez sur "Storage & Database" juste en dessous
  - choisissez "MySQL/MariaDB"
  - saisissez les informations pour que NextCloud puisse se connecter avec votre base
- saisissez l'identifiant et le mot de passe admin que vous voulez, et validez l'installation

🌴 **C'est chez vous ici**, baladez vous un peu sur l'interface de NextCloud, faites le tour du propriétaire :)

🌞 **Exploration de la base de données**

- connectez vous en ligne de commande à la base de données après l'installation terminée

```sh
# connexion à la base de données
[roxanne@web ~]$ mysql -u nextcloud -h 10.102.1.12 -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 52
Server version: 5.5.5-10.5.16-MariaDB MariaDB Server
```

- déterminer combien de tables ont été crées par NextCloud lors de la finalisation de l'installation
  - ***bonus points*** si la réponse à cette question est automatiquement donnée par une requête SQL

```sh
mysql> USE nextcloud;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> SELECT COUNT(*) AS CMPT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TY
PE = 'BASE TABLE';
+------+
| CMPT |
+------+
|   95 |
+------+
1 row in set (0.00 sec)
```
