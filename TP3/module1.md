# Module 1 : Reverse Proxy

Un reverse proxy est donc une machine que l'on place devant un autre service afin d'accueillir les clients et servir d'intermédiaire entre le client et le service.

L'utilisation d'un reverse proxy peut apporter de nombreux bénéfices :

- décharger le service HTTP de devoir effectuer le chiffrement HTTPS (coûteux en performances)
- répartir la charge entre plusieurs services
- effectuer de la mise en cache
- fournir un rempart solide entre un hacker potentiel et le service et les données importantes
- servir de point d'entrée unique pour accéder à plusieurs services web


## Sommaire

- [Module 1 : Reverse Proxy](#module-1--reverse-proxy)
  - [Sommaire](#sommaire)
- [I. Intro](#i-intro)
- [II. Setup](#ii-setup)
- [III. HTTPS](#iii-https)

# I. Intro

# II. Setup

🖥️ **VM `proxy.tp3.linux`**

**N'oubliez pas de dérouler la [📝**checklist**📝](#checklist).**

➜ **On utilisera NGINX comme reverse proxy**

- installer le paquet `nginx`

```sh
[roxanne@proxy ~]$ sudo dnf install nginx
Extra Packages for Enterprise Linux 9 - x86  29 kB/s |  16 kB     00:00
Extra Packages for Enterprise Linux 9 - x86 5.1 MB/s |  11 MB     00:02
[...]

Complete!
```

- démarrer le service `nginx`

```sh
[roxanne@proxy ~]$ sudo systemctl start nginx
[roxanne@proxy ~]$ sudo systemctl enable nginx
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
```

- utiliser la commande `ss` pour repérer le port sur lequel NGINX écoute

```sh
# nginx écoute sur le port 80
[roxanne@proxy ~]$ sudo ss -laptn | grep nginx
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=3131,fd=6),("nginx",pid=3130,fd=6))
LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=3131,fd=7),("nginx",pid=3130,fd=7))
```

- ouvrir un port dans le firewall pour autoriser le trafic vers NGINX

```sh
[roxanne@proxy ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success
[roxanne@proxy ~]$ sudo firewall-cmd --reload
success
[roxanne@proxy ~]$ sudo firewall-cmd --list-ports
22/tcp 80/tcp
```

- utiliser une commande `ps -ef` pour déterminer sous quel utilisateur tourne NGINX

```sh
# NGINX tourne sous l'utilisateur nginx
[roxanne@proxy ~]$ ps -ef | grep nginx
nginx       3131    3130  0 10:58 ?        00:00:00 nginx: worker process
```

- vérifier que le page d'accueil NGINX est disponible en faisant une requête HTTP sur le port 80 de la machine

```sh
[roxanne@proxy ~]$ curl localhost:80
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/
    [...]
```

➜ **Configurer NGINX**

- nous ce qu'on veut, c'pas une page d'accueil moche, c'est que NGINX agisse comme un reverse proxy entre les clients et notre serveur Web
- deux choses à faire :
  - créer un fichier de configuration NGINX
    - la conf est dans `/etc/nginx`
    - procédez comme pour Apache : repérez les fichiers inclus par le fichier de conf principal, et créez votre fichier de conf en conséquence

```sh
[roxanne@proxy ~]$ sudo nano /etc/nginx/nginx.conf
[roxanne@proxy ~]$ cat nginx.conf
server {
    # On indique le nom que client va saisir pour accéder au service
    # Pas d'erreur ici, c'est bien le nom de web, et pas de proxy qu'on veut ici !
    server_name web.tp2.linux;

    # Port d'écoute de NGINX
    listen 80;

    location / {
        # On définit des headers HTTP pour que le proxying se passe bien
        proxy_set_header  Host $host;
        proxy_set_header  X-Real-IP $remote_addr;
        proxy_set_header  X-Forwarded-Proto https;
        proxy_set_header  X-Forwarded-Host $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;

        # On définit la cible du proxying
        proxy_pass http://10.102.1.11:80;
    }

    # Deux sections location recommandés par la doc NextCloud
    location /.well-known/carddav {
      return 301 $scheme://$host/remote.php/dav;
    }

    location /.well-known/caldav {
      return 301 $scheme://$host/remote.php/dav;
    }
}
```

  - NextCloud est un peu exigeant, et il demande à être informé si on le met derrière un reverse proxy
    - y'a donc un fichier de conf NextCloud à modifier
    - c'est un fichier appelé `config.php`

```sh
# ajout du reverse proxy dans le fichier config.php
[roxanne@web ~]$ sudo nano /var/www/tp2_nextcloud/config/config.php
[sudo] password for roxanne:
[roxanne@web ~]$ cat /var/www/tp2_nextcloud/config/config.php
cat: /var/www/tp2_nextcloud/config/config.php: Permission denied
[roxanne@web ~]$ sudo !!
sudo cat /var/www/tp2_nextcloud/config/config.php
<?php
$CONFIG = array (
  'instanceid' => 'oc9jpki6lfgi',
  'passwordsalt' => 'Ks2LXjERO6g4IB51X/rVbfSrbPAkvh',
  'secret' => 'oT/CDQObV0EszuIpwa1GxdypAV7HNQxhs8sXetVo2VCSXLB0',
  'trusted_domains' =>
  array (
    0 => 'web.tp2.linux',
    1 => '10.102.1.13',
  ),
  'datadirectory' => '/var/www/tp2_nextcloud/data',
  'dbtype' => 'mysql',
  'version' => '25.0.0.15',
  'overwrite.cli.url' => 'http://web.tp2.linux',
  'dbname' => 'nextcloud',
  'dbhost' => '10.102.1.12:3306',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud',
  'dbpassword' => 'toto',
  'installed' => true,
);
```

```sh
# redémarrage du serveur apache
[roxanne@web ~]$ sudo systemctl restart httpd
[roxanne@web ~]$ sudo systemctl status httpd
● httpd.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor>
    Drop-In: /usr/lib/systemd/system/httpd.service.d
             └─php81-php-fpm.conf
     Active: active (running) since Thu 2022-11-17 11:19:11 CET; 6s ago
       Docs: man:httpd.service(8)
   Main PID: 1665 (httpd)
     Status: "Started, listening on: port 80"
```

Référez-vous à monsieur Google pour tout ça :)

Exemple de fichier de configuration minimal NGINX.:

```nginx
server {
    # On indique le nom que client va saisir pour accéder au service
    # Pas d'erreur ici, c'est bien le nom de web, et pas de proxy qu'on veut ici !
    server_name web.tp2.linux;

    # Port d'écoute de NGINX
    listen 80;

    location / {
        # On définit des headers HTTP pour que le proxying se passe bien
        proxy_set_header  Host $host;
        proxy_set_header  X-Real-IP $remote_addr;
        proxy_set_header  X-Forwarded-Proto https;
        proxy_set_header  X-Forwarded-Host $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;

        # On définit la cible du proxying 
        proxy_pass http://<IP_DE_NEXTCLOUD>:80;
    }

    # Deux sections location recommandés par la doc NextCloud
    location /.well-known/carddav {
      return 301 $scheme://$host/remote.php/dav;
    }

    location /.well-known/caldav {
      return 301 $scheme://$host/remote.php/dav;
    }
}
```

✨ **Bonus** : rendre le serveur `web.tp2.linux` injoignable sauf depuis l'IP du reverse proxy. En effet, les clients ne doivent pas joindre en direct le serveur web : notre reverse proxy est là pour servir de serveur frontal.

```sh
# Fait au dessus (:
```

# III. HTTPS

Le but de cette section est de permettre une connexion chiffrée lorsqu'un client se connecte. Avoir le ptit HTTPS :)

Le principe :

- on génère une paire de clés sur le serveur `proxy.tp3.linux`
  - une des deux clés sera la clé privée : elle restera sur le serveur et ne bougera jamais
  - l'autre est la clé publique : elle sera stockée dans un fichier appelé *certificat*
    - le *certificat* est donné à chaque client qui se connecte au site
- on ajuste la conf NGINX
  - on lui indique le chemin vers le certificat et la clé privée afin qu'il puisse les utiliser pour chiffrer le trafic
  - on lui demande d'écouter sur le port convetionnel pour HTTPS : 443 en TCP

Je vous laisse Google vous-mêmes "nginx reverse proxy nextcloud" ou ce genre de chose :)

```sh
# installation de certbot
[roxanne@proxy ~]$ sudo dnf install certbot
Last metadata expiration check: 0:52:27 ago on Thu 17 Nov 2022 11:26:22 CET.
Dependencies resolved.
============================================================================
 Package                   Arch   Version                   Repo       Size
============================================================================
[...]

Complete!

[roxanne@proxy ~]$ sudo dnf install python3-certbot-nginx
Last metadata expiration check: 0:58:10 ago on Thu 17 Nov 2022 11:26:22 CET.
Dependencies resolved.
[...]

Complete!
```

```sh
# ouverture du port https
[roxanne@proxy ~]$ sudo firewall-cmd --add-port=443/tcp --permanent
[sudo] password for roxanne:
success
[roxanne@proxy ~]$ sudo firewall-cmd --reload
success

# fermeture du port http
[roxanne@proxy ~]$ sudo firewall-cmd --remove-port=80/tcp
success
[roxanne@proxy ~]$ sudo firewall-cmd --list-port
22/tcp 443/tcp
```

```sh
# génération du certificat
[roxanne@proxy ~]$ openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt
[...]
-----
Country Name (2 letter code) [XX]:
State or Province Name (full name) []:
Locality Name (eg, city) [Default City]:
Organization Name (eg, company) [Default Company Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (eg, your name or your server's hostname) []:web.tp2.linux
Email Address []:
```

```sh
# rennomage des fichiers
[roxanne@proxy ~]$ mv server.crt web.tp2.linux.crt
[roxanne@proxy ~]$ mv server.key web.tp2.linux.key
[roxanne@proxy ~]$ ls
web.tp2.linux.crt  web.tp2.linux.key

# déplacement des fichiers dans des dossiers appropriés
[roxanne@proxy ~]$ sudo mv web.tp2.linux.crt /etc/pki/tls/certs/
[roxanne@proxy ~]$ sudo ls /etc/pki/tls/certs
ca-bundle.crt  ca-bundle.trust.crt  web.tp2.linux.crt
[roxanne@proxy ~]$ sudo mv web.tp2.linux.key /etc/pki/tls/private/
[roxanne@proxy ~]$ sudo ls /etc/pki/tls/private/
web.tp2.linux.key
```

```sh
# passage en https
[roxanne@proxy ~]$ sudo nano /etc/nginx/nginx.conf
[roxanne@proxy ~]$ sudo cat /etc/nginx/nginx.conf
[...]

server {
    # On indique le nom que client va saisir pour accéder au service
    # Pas d'erreur ici, c'est bien le nom de web, et pas de proxy qu'on veut ici !
    server_name web.tp2.linux;

    # Port d'écoute de NGINX
    listen 443 ssl;

    ssl_certificate /etc/pki/tls/certs/web.tp2.linux.cert;
    ssl_certificate_key /etc/pki/tls/private/web.tp2.linux.key;

    location / {
        # On définit des headers HTTP pour que le proxying se passe bien
        proxy_set_header  Host $host;
        proxy_set_header  X-Real-IP $remote_addr;
        proxy_set_header  X-Forwarded-Proto https;
        proxy_set_header  X-Forwarded-Host $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;

        # On définit la cible du proxying
        proxy_pass http://10.102.1.11:80;
    }

    # Deux sections location recommandés par la doc NextCloud
    location /.well-known/carddav {
      return 301 $scheme://$host/remote.php/dav;
    }

    location /.well-known/caldav {
      return 301 $scheme://$host/remote.php/dav;
    }
}

[...]
```

```sh
# redémarrage du service
[roxanne@proxy ~]$ sudo systemctl restart nginx
```

```sh
# passage de la conf web en https
[roxanne@web ~]$ sudo vi /var/www/tp2_nextcloud/config/config.php
[sudo] password for roxanne:
[roxanne@web ~]$ sudo cat /var/www/tp2_nextcloud/config/config.php
<?php
$CONFIG = array (
  'instanceid' => 'oc9jpki6lfgi',
  'passwordsalt' => 'Ks2LXjERO6g4IB51X/rVbfSrbPAkvh',
  'secret' => 'oT/CDQObV0EszuIpwa1GxdypAV7HNQxhs8sXetVo2VCSXLB0',
  'trusted_domains' =>
  array (
          0 => 'web.tp2.linux',
          1 => '10.102.1.13',
  ),
  'datadirectory' => '/var/www/tp2_nextcloud/data',
  'dbtype' => 'mysql',
  'version' => '25.0.0.15',
  'overwrite.cli.url' => 'https://web.tp2.linux',
  'overwriteprotocol' => 'https',
  'dbname' => 'nextcloud',
  'dbhost' => '10.102.1.12:3306',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud',
  'dbpassword' => 'toto',
  'installed' => true,
);
```

```sh
# redémarrage du service
[roxanne@web ~]$ sudo systemctl restart httpd
```

```sh
ça fonctionne !!
```