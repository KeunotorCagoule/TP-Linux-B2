# Module 7 : Fail2Ban

Fail2Ban c'est un peu le cas d'école de l'admin Linux, je vous laisse Google pour le mettre en place.

C'est must-have sur n'importe quel serveur à peu de choses près. En plus d'enrayer les attaques par bruteforce, il limite aussi l'imact sur les performances de ces attaques, en bloquant complètement le trafic venant des IP considérées comme malveillantes

Faites en sorte que :

- si quelqu'un se plante 3 fois de password pour une co SSH en moins de 1 minute, il est ban
- vérifiez que ça fonctionne en vous faisant ban
- afficher la ligne dans le firewall qui met en place le ban
- lever le ban avec une commande liée à fail2ban

> Vous pouvez vous faire ban en effectuant une connexion SSH depuis `web.tp2.linux` vers `db.tp2.linux` par exemple, comme ça vous gardez intacte la connexion de votre PC vers `db.tp2.linux`, et vous pouvez continuer à bosser en SSH.

```sh
[roxanne@web ~]$ sudo dnf install fail2ban
[sudo] password for roxanne:
Last metadata expiration check: 1:02:20 ago on Mon 21 Nov 2022 11:06:10 CET.
Dependencies resolved.
[...]

Complete!
```

```sh
# lancement du service
[roxanne@web ~]$ sudo systemctl start fail2ban
[roxanne@web ~]$ sudo systemctl enable fail2ban
Created symlink /etc/systemd/system/multi-user.target.wants/fail2ban.service → /usr/lib/systemd/system/fail2ban.service.
[roxanne@web ~]$ sudo systemctl status fail2ban
● fail2ban.service - Fail2Ban Service
     Loaded: loaded (/usr/lib/systemd/system/fail2ban.service; enabled; ven>
     Active: active (running) since Mon 2022-11-21 12:12:59 CET; 14s ago
       Docs: man:fail2ban(1)
   Main PID: 3676 (fail2ban-server)
      Tasks: 3 (limit: 5896)
     Memory: 12.3M
        CPU: 94ms
     CGroup: /system.slice/fail2ban.service
             └─3676 /usr/bin/python3 -s /usr/bin/fail2ban-server -xf start

Nov 21 12:12:59 web.tp2.linux systemd[1]: Starting Fail2Ban Service...
Nov 21 12:12:59 web.tp2.linux systemd[1]: Started Fail2Ban Service.
Nov 21 12:12:59 web.tp2.linux fail2ban-server[3676]: 2022-11-21 12:12:59,36>
Nov 21 12:12:59 web.tp2.linux fail2ban-server[3676]: Server ready
```

```sh
# modification du fichier de configuration de Fail2Ban
[roxanne@web ~]$ sudo vim /etc/fail2ban/jail.local
```