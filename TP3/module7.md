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
[roxanne@web ~]$ cat /etc/fail2ban/jail.local | grep ignore
[...]
# "ignoreip" can be a list of IP addresses, CIDR masks or DNS hosts. Fail2ban
ignoreip = 127.0.0.1 ::1
[...]
```

```sh
# déplcement du fichier de configuration de Fail2Ban pour le faire fonctionner avec firewalld au lieu de iptables
[roxanne@web ~]$ sudo mv /etc/fail2ban/jail.d/00-firewalld.conf /etc/fail2ban/jail.d/00-firewalld.local
```

```sh
# restart du service
[roxanne@web ~]$ sudo systemctl restart fail2ban
```

```sh
# modification du fichier de configuration de Fail2Ban
[roxanne@web ~]$ sudo vim /etc/fail2ban/jail.d/sshd.local
[roxanne@web ~]$ cat /etc/fail2ban/jail.d/sshd.local
[sshd]
enabled = true

bantime = -1
maxretry = 3
findtime = 1m
```

```sh
# restart du service
[roxanne@web ~]$ sudo systemctl restart fail2ban

# vérification du fonctionnement
[roxanne@web ~]$ sudo fail2ban-client status
Status
|- Number of jail:      1
`- Jail list:   sshd

# Vérification de l'override des valeurs par défaut
[roxanne@web ~]$ sudo fail2ban-client get sshd maxretry
3
```

```sh
# vérfication du fonctionnement de Fail2Ban
[roxanne@db ~]$ ssh roxanne@10.102.1.11
The authenticity of host '10.102.1.11 (10.102.1.11)' can't be established.
ED25519 key fingerprint is SHA256:AEROsrvBiVHyJp9/E5DIQE1RMlYmdwG6Zb7x0FnJOq0.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.102.1.11' (ED25519) to the list of known hosts.
roxanne@10.102.1.11's password:
Permission denied, please try again.
roxanne@10.102.1.11's password:
Permission denied, please try again.
roxanne@10.102.1.11's password:
roxanne@10.102.1.11: Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).
```

```sh
# On affiche la règle de blocage (ban) dans le firewall
[roxanne@web ~]$ sudo firewall-cmd --list-rich-rules
rule family="ipv4" source address="10.102.1.12" port port="ssh" protocol="tcp" reject type="icmp-port-unreachable"

# On vérifie également dans fail2ban
[roxanne@web ~]$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     3
|  `- Journal matches:  _SYSTEMD_UNIT=sshd.service + _COMM=sshd
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   10.102.1.12
```

```sh
# On unban à l'aide cette commande
[roxanne@web ~]$ sudo fail2ban-client unban 10.102.1.12
1

# On vérifie que le ban est levé
[roxanne@web ~]$ sudo firewall-cmd --list-rich-rules

[roxanne@web ~]$
```
