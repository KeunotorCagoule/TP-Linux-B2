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

📁 **`Dockerfile`**

# III. `docker-compose`

## 1. Intro

➜ **Installer `docker-compose` sur la machine**

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

📁 📁 `app/Dockerfile` et `app/docker-compose.yml`. Je veux un sous-dossier `app/` sur votre dépôt git avec ces deux fichiers dedans :)
