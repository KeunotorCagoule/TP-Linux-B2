# TP4 : Conteneurs

Dans ce TP on va aborder plusieurs points autour de la conteneurisation : 

- Docker et son empreinte sur le système
- Manipulation d'images
- `docker-compose`

![Headaches](./pics/headaches.jpg)

# Sommaire

- [TP4 : Conteneurs](#tp4--conteneurs)
- [Sommaire](#sommaire)
- [0. Prérequis](#0-prérequis)
  - [Checklist](#checklist)
- [I. Docker](#i-docker)
  - [1. Install](#1-install)
  - [2. Vérifier l'install](#2-vérifier-linstall)
  - [3. Lancement de conteneurs](#3-lancement-de-conteneurs)
- [II. Images](#ii-images)
- [III. `docker-compose`](#iii-docker-compose)
  - [1. Intro](#1-intro)
  - [2. Make your own meow](#2-make-your-own-meow)

# 0. Prérequis

➜ Machines Rocky Linux

➜ Un unique host-only côté VBox, ça suffira. **L'adresse du réseau host-only sera `10.104.1.0/24`.**

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

# I. Docker

🖥️ Machine **docker1.tp4.linux**

## 1. Install

🌞 **Installer Docker sur la machine**

- en suivant [la doc officielle](https://docs.docker.com/engine/install/)
- démarrer le service `docker` avec une commande `systemctl`
- ajouter votre utilisateur au groupe `docker`
  - cela permet d'utiliser Docker sans avoir besoin de l'identité de `root`
  - avec la commande : `sudo usermod -aG docker $(whoami)`
  - déconnectez-vous puis relancez une session pour que le changement prenne effet

```sh
# montage du repo
[roxanne@docker ~]$ sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
[sudo] password for roxanne:
Adding repo from: https://download.docker.com/linux/centos/docker-ce.repo
```

```sh
# installation de la dernière version de docker
[roxanne@docker ~]$ sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin
Docker CE Stable - x86_64                   816  B/s |  12 kB     00:15
Last metadata expiration check: 0:00:15 ago on Thu 24 Nov 2022 11:13:12 CET.
Dependencies resolved.
[...]

Complete!
```

```sh
# démarrage du service docker
[roxanne@docker ~]$ sudo systemctl start docker
[sudo] password for roxanne:
[roxanne@docker ~]$ sudo systemctl enable docker
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
```

```sh
[roxanne@docker ~]$ sudo systemctl enable docker
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
[roxanne@docker ~]$ sudo docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
2db29710123e: Pull complete
Digest: sha256:faa03e786c97f07ef34423fccceeec2398ec8a5759259f94d99078f264e9d7af
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
[...]

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

```sh
# ajout de l'utilisateur roxanne au groupe docker
[roxanne@docker ~]$ sudo usermod -a -G docker roxanne
```

## 2. Vérifier l'install

➜ **Vérifiez que Docker est actif est disponible en essayant quelques commandes usuelles :**

```bash
# Info sur l'install actuelle de Docker
$ docker info

# Liste des conteneurs actifs
$ docker ps
# Liste de tous les conteneurs
$ docker ps -a

# Liste des images disponibles localement
$ docker images

# Lancer un conteneur debian
$ docker run debian
$ docker run -d debian sleep 99999
$ docker run -it debian bash

# Consulter les logs d'un conteneur
$ docker ps # on repère l'ID/le nom du conteneur voulu
$ docker logs <ID_OR_NAME>
$ docker logs -f <ID_OR_NAME> # suit l'arrivée des logs en temps réel

# Exécuter un processus dans un conteneur actif
$ docker ps # on repère l'ID/le nom du conteneur voulu
$ docker exec <ID_OR_NAME> <COMMAND>
$ docker exec <ID_OR_NAME> ls
$ docker exec -it <ID_OR_NAME> bash # permet de récupérer un shell bash dans le conteneur ciblé
```

➜ **Explorer un peu le help**, si c'est pas le man :

```bash
$ docker --help
$ docker run --help
$ man docker
```

## 3. Lancement de conteneurs

La commande pour lancer des conteneurs est `docker run`.

Certaines options sont très souvent utilisées :

```bash
# L'option --name permet de définir un nom pour le conteneur
$ docker run --name web nginx

# L'option -d permet de lancer un conteneur en tâche de fond
$ docker run --name web -d nginx

# L'option -v permet de partager un dossier/un fichier entre l'hôte et le conteneur
$ docker run --name web -d -v /path/to/html:/usr/share/nginx/html nginx

# L'option -p permet de partager un port entre l'hôte et le conteneur
$ docker run --name web -d -v /path/to/html:/usr/share/nginx/html -p 8888:80 nginx
# Dans l'exemple ci-dessus, le port 8888 de l'hôte est partagé vers le port 80 du conteneur
```

🌞 **Utiliser la commande `docker run`**

- lancer un conteneur `nginx`
  - l'app NGINX doit avoir un fichier de conf personnalisé
  - l'app NGINX doit servir un fichier `index.html` personnalisé
  - l'application doit être joignable grâce à un partage de ports
  - vous limiterez l'utilisation de la RAM et du CPU de ce conteneur
  - le conteneur devra avoir un nom
  - le processus exécuté par le conteneur doit être un utilisateur de votre choix (pas `root`)

> Tout se fait avec des options de la commande `docker run`.

```sh
[roxanne@docker ~]$ docker run --name web -m="1g" --cpus="1.0" -d -v /var/nginx/html:/usr/share/nginx/html -p 8888:80 nginx
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
a603fa5e3b41: Pull complete
c39e1cda007e: Pull complete
90cfefba34d7: Pull complete
a38226fb7aba: Pull complete
62583498bae6: Pull complete
9802a2cfdb8d: Pull complete
Digest: sha256:e209ac2f37c70c1e0e9873a5f7231e91dcd83fdf1178d8ed36c2ec09974210ba
Status: Downloaded newer image for nginx:latest
bf75a962ec491c08c50581121ff1c5a326048e83e71c348799ec601438cb682b
```

```sh
# création du fichier de conf
[roxanne@docker html]$ sudo vim index.html
[roxanne@docker html]$ cat index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Tenders</title>
</head>
<body>
        <h1>omelette</h1>
</body>
</html>
```

```sh
# ouverture du port 8888
[roxanne@docker html]$ sudo firewall-cmd --add-port=8888/tcp --permanent
success
[roxanne@docker html]$ sudo firewall-cmd --reload
success

# accès à la page web
[roxanne@docker html]$ curl 10.104.1.11:8888
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Tenders</title>
</head>
<body>
        <h1>omelette</h1>
</body>
</html>
```

```sh
# création du fichier de conf nginx
[roxanne@docker nginx]$ sudo vim custom.conf
[sudo] password for roxanne:
[roxanne@docker nginx]$ cat custom.conf
server {
  # on définit le port où NGINX écoute dans le conteneur
  listen 80;

  # on définit le chemin vers la racine web
  # dans ce dossier doit se trouver un fichier index.html
  location / {
        root /var/www/tp4;
  }
}
```

```sh
# supression du conteneur web
[roxanne@docker nginx]$ docker run --name web -m="1g" --cpus="1.0" -d -v /var/nginx/html:/usr/share/nginx/html -v /var/nginx/nginx/custom.conf:/etc/nginx/conf.d/custom.conf -p 8888:80 nginx
docker: Error response from daemon: Conflict. The container name "/web" is already in use by container "bf75a962ec491c08c50581121ff1c5a326048e83e71c348799ec601438cb682b". You have to remove (or rename) that container to be able to reuse that name.
See 'docker run --help'.
[roxanne@docker nginx]$ docker stop web
web
[roxanne@docker nginx]$ docker rm web
web

# re-création du conteneur web
[roxanne@docker nginx]$ docker run --name web -m="1g" --cpus="1.0" -d -v /var/nginx/html:/usr/share/nginx/html -v /var/nginx/nginx/custom.conf:/etc/nginx/conf.d/custom.conf -p 8888:80 nginx
361110a988e4c99e7a2ddddd3362d47507d1439e75c0d1fa6054ec0f57108106
```

# II. Images

La construction d'image avec Docker est basée sur l'utilisation de fichiers `Dockerfile`.

L'idée est la suivante :

- vous créez un dossier de travail
- vous vous déplacez dans ce dossier de travail
- vous créez un fichier `Dockerfile`
  - il contient les instructions pour construire une image
  - `FROM` : indique l'image de base
  - `RUN` : indique des opérations à effectuer dans l'image de base
- vous exécutez une commande `docker build . -t <IMAGE_NAME>`
- une image est produite, visible avec la commande `docker images`

## Exemple de Dockerfile et utilisation

Exemple d'un Dockerfile qui :

- se base sur une image ubuntu
- la met à jour
- installe nginx

```bash
$ cat Dockerfile
FROM ubuntu

RUN apt update -y

RUN apt install -y nginx
```

Une fois ce fichier créé, on peut :

```bash
$ ls
Dockerfile

$ docker build . -t my_own_nginx 

$ docker images

$ docker run -p 8888:80 my_own_nginx nginx -g "daemon off;"

$ curl localhost:8888
$ curl <IP_VM>:8888
```

> La commande `nginx -g "daemon off;"` permet de lancer NGINX au premier-plan, et ainsi demande à notre conteneur d'exécuter le programme NGINX à son lancement.

Plutôt que de préciser à la main à chaque `docker run` quelle commande doit lancer le conteneur (notre `nginx -g "daemon off;"` en fin de ligne ici), on peut, au moment du `build` de l'image, choisir d'indiquer que chaque conteneur lancé à partir de cette image lancera une commande donneé.

Il faut, pour cela, modifier le Dockerfile :

```bash
$ cat Dockerfile
FROM ubuntu

RUN apt update -y

RUN apt install -y nginx

CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
```

```bash
$ ls
Dockerfile

$ docker build . -t my_own_nginx

$ docker images

$ docker run -p 8888:80 my_own_nginx

$ curl localhost:8888
$ curl <IP_VM>:8888
```


![Waiting for Docker](./pics/waiting_for_docker.jpg)

## 2. Construisez votre propre Dockerfile

🌞 **Construire votre propre image**

- image de base (celle que vous voulez : debian, alpine, ubuntu, etc.)
  - une image du Docker Hub
  - qui ne porte aucune application par défaut
- vous ajouterez
  - mise à jour du système
  - installation de Apache
  - page d'accueil Apache HTML personnalisée

```sh
# création du dossier apache
[roxanne@docker ~]$ mkdir apache
[roxanne@docker ~]$ cd apache/
[roxanne@docker apache]$ sudo cp /var/nginx/html/index.html .
[sudo] password for roxanne:
[roxanne@docker apache]$ ls
index.html

# attribution du fichier index.html à l'utilisateur roxanne 
[roxanne@docker apache]$ sudo chown roxanne:roxanne index.html

# création du fichier de conf personnalisé d'apache
[roxanne@docker apache]$ vim custom.conf
[roxanne@docker apache]$ cat custom.conf
# on définit un port sur lequel écouter
Listen 80

# on charge certains modules Apache strictement nécessaires à son bon fonctionnement
LoadModule mpm_event_module "/usr/lib/apache2/modules/mod_mpm_event.so"
LoadModule dir_module "/usr/lib/apache2/modules/mod_dir.so"
LoadModule authz_core_module "/usr/lib/apache2/modules/mod_authz_core.so"

# on indique le nom du fichier HTML à charger par défaut
DirectoryIndex index.html
# on indique le chemin où se trouve notre site
DocumentRoot "/var/www/html/"

# quelques paramètres pour les logs
ErrorLog "logs/error.log"
LogLevel warn
```  

```sh
[roxanne@docker apache]$ vim Dockerfile
[roxanne@docker apache]$ cat Dockerfile
FROM ubuntu
RUN apt update -y
RUN apt install apache2 -y
RUN mkdir -p /var/www/html


ADD index.html /var/www/html/index.html
ADD custom.conf /etc/apache2/apache2.conf

RUN mkdir -p /etc/apache2/logs
RUN chmod 755 /etc/apache2/logs

CMD ["apache2", "-D", "FOREGROUND"]
```

📁 [Dockerfile](./Dockerfile)

```sh
[roxanne@docker apache]$ docker build . -t own_apache
Sending build context to Docker daemon  4.608kB
Step 1/9 : FROM ubuntu
[...]
Successfully built bac43a7e4cd9
Successfully tagged own_apache:latest

# vérification de l'image créée
[roxanne@docker apache]$ docker images
REPOSITORY    TAG       IMAGE ID       CREATED              SIZE
own_apache    latest    bac43a7e4cd9   About a minute ago   225MB
[...]  
```

```sh
# lancement du conteneur
[roxanne@docker apache]$ docker run -d -p 8888:80 own_apache
dc0efc01cf93dacc02371e2c1885aa0ccd222ffbb55f9086ac72f74db44d7f16
[roxanne@docker apache]$ docker ps
CONTAINER ID   IMAGE        COMMAND                  CREATED         STATUS         PORTS                                   NAMES
dc0efc01cf93   own_apache   "apache2 -D FOREGROU…"   8 seconds ago   Up 7 seconds   0.0.0.0:8888->80/tcp, :::8888->80/tcp   nervous_ride
```

```sh
# vérification du fonctionnement
[roxanne@docker apache]$ curl 10.104.1.11:8888
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Tenders</title>
</head>
<body>
        <h1>omelette</h1>
</body>
</html>
```

# III. `docker-compose`

## 1. Intro

➜ **Installer `docker-compose` sur la machine**

```sh
#Done
```

- en suivant [la doc officielle](https://docs.docker.com/compose/install/)

`docker-compose` est un outil qui permet de lancer plusieurs conteneurs en une seule commande.

> En plus d'être pratique, il fournit des fonctionnalités additionnelles, liés au fait qu'il s'occupe à lui tout seul de lancer tous les conteneurs. On peut par exemple demander à un conteneur de ne s'allumer que lorsqu'un autre conteneur est devenu "healthy". Idéal pour lancer une application après sa base de données par exemple.

Le principe de fonctionnement de `docker-compose` :

- on écrit un fichier qui décrit les conteneurs voulus
  - c'est le `docker-compose.yml`
  - tout ce que vous écriviez sur la ligne `docker run` peut être écrit sous la forme d'un `docker-compose.yml`
- on se déplace dans le dossier qui contient le `docker-compose.yml`
- on peut utiliser les commandes `docker-compose` :

```bash
# Allumer les conteneurs définis dans le docker-compose.yml
$ docker-compose up
$ docker-compose up -d

# Eteindre
$ docker-compose down

# Explorer un peu le help, il y a d'autres commandes utiles
$ docker-compose --help
```

La syntaxe du fichier peut par exemple ressembler à :

```yml
version: "3.8"

services:
  db:
    image: mysql:5.7
    restart: always
    ports:
      - '3306:3306'
    volumes:
      - "./db/mysql_files:/var/lib/mysql"
    environment:
      MYSQL_ROOT_PASSWORD: beep
      MYSQL_DATABASE: bip
      MYSQL_USER: bap
      MYSQL_PASSWORD: boop

  nginx:
    image: nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    restart: unless-stopped
```

> Pour connaître les variables d'environnement qu'on peut passer à un conteneur, comme `MYSQL_ROOT_PASSWORD` au dessus, il faut se rendre sur la doc de l'image en question, sur le Docker Hub par exemple.

## 2. Make your own meow

Pour cette partie, vous utiliserez une application à vous que vous avez sous la main.

N'importe quelle app fera le taff, un truc dév en cours, en temps perso, au taff, peu importe.

Peu importe le langage aussi ! Go, Python, PHP (désolé des gros mots), Node (j'ai déjà dit désolé pour les gros mots ?), ou autres.

🌞 **Conteneurisez votre application**

- créer un `Dockerfile` maison qui porte l'application
- créer un `docker-compose.yml` qui permet de lancer votre application
- vous préciserez dans le rendu les instructions pour lancer l'application
  - indiquer la commande `git clone`
  - le `cd` dans le bon dossier
  - la commande `docker build` pour build l'image
  - la commande `docker-compose` pour lancer le(s) conteneur(s)

```sh
# installation de git pour pouvoir cloner l'application
[roxanne@docker ~]$ sudo dnf install git-all
[sudo] password for roxanne:
Rocky Linux 9 - BaseOS                      8.4 kB/s | 3.6 kB     00:00
Rocky Linux 9 - AppStream                   8.9 kB/s | 3.6 kB     00:00
Rocky Linux 9 - Extras                      7.2 kB/s | 2.9 kB     00:00
Dependencies resolved.
[...]
Complete!
``` 

```sh
# clonage de l'application
[roxanne@docker ~]$ git clone https://ytrack.learn.ynov.com/git/AVASSEUR2/Groupie-Tracker.git
Cloning into 'Groupie-Tracker'...
Username for 'https://ytrack.learn.ynov.com': roxanne.roulland@ynov.com
Password for 'https://roxanne.roulland@ynov.com@ytrack.learn.ynov.com':
remote: Enumerating objects: 491, done.
remote: Counting objects: 100% (491/491), done.
remote: Compressing objects: 100% (468/468), done.
remote: Total 491 (delta 305), reused 0 (delta 0), pack-reused 0
Receiving objects: 100% (491/491), 236.58 KiB | 700.00 KiB/s, done.
Resolving deltas: 100% (305/305), done.
```

```sh
# création d'un .dockerignore pour qu'on ne puisse pas modifier le repo git depuis le conteneur
[roxanne@docker ~]$ cd Groupie-Tracker/
[roxanne@docker Groupie-Tracker]$ vim .dockerignore
[roxanne@docker Groupie-Tracker]$ cat .dockerignore
.git
```

```sh
# création du Dockerfile (Image)
[roxanne@docker Groupie-Tracker]$ vim Dockerfile
[roxanne@docker Groupie-Tracker]$ cat Dockerfile
FROM golang
RUN mkdir -p /var/www/html

WORKDIR /usr/src/app

COPY . .

EXPOSE 80

CMD ["go", "run", "./server/server.go"]
```

```sh
# build de l'image de groupie_tracker
[roxanne@docker Groupie-Tracker]$ docker build . -t groupie_tracker
Sending build context to Docker daemon  256.5kB
Step 1/6 : FROM golang
latest: Pulling from library/golang
a8ca11554fce: Pull complete
e4e46864aba2: Pull complete
c85a0be79bfb: Pull complete
195ea6a58ca8: Pull complete
52908dc1c386: Pull complete
a2b47720d601: Pull complete
14a70245b07c: Pull complete
Digest: sha256:dc76ef03e54c34a00dcdca81e55c242d24b34d231637776c4bb5c1a8e8514253
Status: Downloaded newer image for golang:latest
 ---> 8ee516e10ce0
Step 2/6 : RUN mkdir -p /var/www/html
 ---> Running in a82abc3de666
Removing intermediate container a82abc3de666
 ---> ec12f2d8da88
Step 3/6 : WORKDIR /usr/src/app
 ---> Running in 60402cdf9dfc
Removing intermediate container 60402cdf9dfc
 ---> 30169c8825e1
Step 4/6 : COPY . .
 ---> c18bf8267542
Step 5/6 : EXPOSE 80
 ---> Running in 890b5081e7df
Removing intermediate container 890b5081e7df
 ---> 2841766bb0fb
Step 6/6 : CMD ["go", "run", "./server/server.go"]
 ---> Running in 6d6cb5a824a8
Removing intermediate container 6d6cb5a824a8
 ---> 1d5bf6e18e70
Successfully built 1d5bf6e18e70
Successfully tagged groupie_tracker:latest
```

```sh
# création du docker-compose.yml
[roxanne@docker Groupie-Tracker]$ vim docker-compose.yml
[roxanne@docker Groupie-Tracker]$ cat docker-compose.yml
services:
  groupie:
    image: groupie_tracker
    restart: always
    ports:
      - 8888:80
```

```sh
# lancement du conteneur
[roxanne@docker Groupie-Tracker]$ docker compose up -d
[+] Running 1/1
 ⠿ Container groupie-tracker-groupie-1  Started                        0.3s
[roxanne@docker Groupie-Tracker]$ docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS         PORTS                                   NAMES
c40a0c377fb4   groupie_tracker   "go run ./server/ser…"   51 seconds ago   Up 7 seconds   0.0.0.0:8888->80/tcp, :::8888->80/tcp   groupie-tracker-groupie-1
```

```sh
# vérification que l'application est bien lancée
[roxanne@docker Groupie-Tracker]$ curl 10.104.1.11:8888
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <link rel="icon" href="/assets/images/favicon.png" type="image/png">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Groupie Tracker</title>
    <link rel="stylesheet" href="/css/globals.css">
    <link rel="stylesheet" href="/css/animations.css">
    <link rel="stylesheet" href="/css/index.css">
</head>

<body>
    <section class="landing">
        <div id="toggler"></div>
[...]

[roxanne@docker Groupie-Tracker]$ curl localhost:8888
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <link rel="icon" href="/assets/images/favicon.png" type="image/png">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Groupie Tracker</title>
    <link rel="stylesheet" href="/css/globals.css">
    <link rel="stylesheet" href="/css/animations.css">
    <link rel="stylesheet" href="/css/index.css">
</head>

<body>
    <section class="landing">
        <div id="toggler"></div>
[...]
```

📁 📁 `app/Dockerfile` et `app/docker-compose.yml`. Je veux un sous-dossier `app/` sur votre dépôt git avec ces deux fichiers dedans :)

[Dossier App ici](./app)
