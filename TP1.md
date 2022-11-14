# TP1 : (re)Familiaration avec un système GNU/Linux

Dans ce TP, on va passer en revue des éléments de configurations élémentaires du système.

Vous pouvez effectuer ces actions dans la première VM. On la clonera ensuite avec toutes les configurations pré-effectuées.

Au menu :

- gestion d'utilisateurs
  - sudo
  - SSH et clés
- configuration réseau
- gestion de partitions
- gestion de services

## Sommaire

- [TP1 : (re)Familiaration avec un système GNU/Linux](#tp1--refamiliaration-avec-un-système-gnulinux)
  - [Sommaire](#sommaire)
  - [0. Préparation de la machine](#0-préparation-de-la-machine)
  - [I. Utilisateurs](#i-utilisateurs)
    - [1. Création et configuration](#1-création-et-configuration)
    - [2. SSH](#2-ssh)
  - [II. Partitionnement](#ii-partitionnement)
    - [1. Préparation de la VM](#1-préparation-de-la-vm)
    - [2. Partitionnement](#2-partitionnement)
  - [III. Gestion de services](#iii-gestion-de-services)
  - [1. Interaction avec un service existant](#1-interaction-avec-un-service-existant)
  - [2. Création de service](#2-création-de-service)
    - [A. Unité simpliste](#a-unité-simpliste)
    - [B. Modification de l'unité](#b-modification-de-lunité)

## 0. Préparation de la machine

> **POUR RAPPEL** pour chacune des opérations, vous devez fournir dans le compte-rendu : comment réaliser l'opération ET la preuve que l'opération a été bien réalisée

🌞 **Setup de deux machines Rocky Linux configurées de façon basique.**

- **un accès internet (via la carte NAT)**
  - carte réseau dédiée
  - route par défaut

```bash
# node1 a internet
[roxanne@node1 ~]$ ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=113 time=26.5 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=113 time=26.7 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=113 time=25.1 ms
^C
--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 25.103/26.078/26.676/0.695 ms
```

```bash
# node2 a internet
[roxanne@node2 ~]$ ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=113 time=30.0 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=113 time=22.8 ms
^C
--- 8.8.8.8 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 22.841/26.419/29.998/3.578 ms
```

- **un accès à un réseau local** (les deux machines peuvent se `ping`) (via la carte Host-Only)
  - carte réseau dédiée (host-only sur VirtualBox)
  - les machines doivent posséder une IP statique sur l'interface host-only

```bash
# node1 vers node2
[roxanne@node1 ~]$ ping 10.101.1.12
PING 10.101.1.12 (10.101.1.12) 56(84) bytes of data.
64 bytes from 10.101.1.12: icmp_seq=1 ttl=64 time=0.629 ms
64 bytes from 10.101.1.12: icmp_seq=2 ttl=64 time=0.437 ms
64 bytes from 10.101.1.12: icmp_seq=3 ttl=64 time=0.536 ms
^C
--- 10.101.1.12 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2085ms
rtt min/avg/max/mdev = 0.437/0.534/0.629/0.078 ms

# node2 vers node1
[roxanne@node2 ~]$ ping 10.101.1.11
PING 10.101.1.11 (10.101.1.11) 56(84) bytes of data.
64 bytes from 10.101.1.11: icmp_seq=1 ttl=64 time=0.406 ms
64 bytes from 10.101.1.11: icmp_seq=2 ttl=64 time=0.491 ms
^C
--- 10.101.1.11 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1020ms
rtt min/avg/max/mdev = 0.406/0.448/0.491/0.042 ms
```

- **vous n'utilisez QUE `ssh` pour administrer les machines**

- **les machines doivent avoir un nom**
  - référez-vous au mémo
  - les noms que doivent posséder vos machines sont précisés dans le tableau plus bas

```bash
[roxanne@localhost ~]$ sudo nano /etc/hostname
[roxanne@node1 ~]$ cat /etc/hostname
node1.tp1.b2
```

```bash
[roxanne@localhost ~]$ sudo nano /etc/hostname
[roxanne@node2 ~]$ cat /etc/hostname
node2.tp1.b2
```

- **utiliser `1.1.1.1` comme serveur DNS**
  - référez-vous au mémo
  - vérifier avec le bon fonctionnement avec la commande `dig`
    - avec `dig`, demander une résolution du nom `ynov.com`
    - mettre en évidence la ligne qui contient la réponse : l'IP qui correspond au nom demandé
    - mettre en évidence la ligne qui contient l'adresse IP du serveur qui vous a répondu

```
[roxanne@node1 ~]$ sudo nano /etc/resolv.conf
[sudo] password for roxanne:
[roxanne@node1 ~]$ sudo cat /etc/resolv.conf
nameserver 1.1.1.1
[roxanne@node1 ~]$ dig ynov.com

; <<>> DiG 9.16.23-RH <<>> ynov.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 32432
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;ynov.com.                      IN      A

;; ANSWER SECTION:
ynov.com.               35      IN      A       104.26.11.233
ynov.com.               35      IN      A       172.67.74.226
ynov.com.               35      IN      A       104.26.10.233
# !! 104.26.11.233 est l'ip d'ynov.com

;; Query time: 27 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
# !! le serveur DNS utilisé est bien 1.1.1.1
;; WHEN: Mon Nov 14 11:53:49 CET 2022
;; MSG SIZE  rcvd: 85
```

```
[roxanne@node2 ~]$ sudo nano /etc/resolv.conf
[roxanne@node2 ~]$ sudo cat /etc/resolv.conf
nameserver 1.1.1.1
[roxanne@node2 ~]$ dig ynov.com

; <<>> DiG 9.16.23-RH <<>> ynov.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 2898
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;ynov.com.                      IN      A

;; ANSWER SECTION:
ynov.com.               269     IN      A       172.67.74.226
ynov.com.               269     IN      A       104.26.10.233
ynov.com.               269     IN      A       104.26.11.233
# !! 104.26.11.233 est l'ip d'ynov.com

;; Query time: 27 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
# !! le serveur DNS utilisé est bien 1.1.1.1
;; WHEN: Mon Nov 14 11:49:55 CET 2022
;; MSG SIZE  rcvd: 85
```

- **les machines doivent pouvoir se joindre par leurs noms respectifs**
  - fichier `/etc/hosts`
  - assurez-vous du bon fonctionnement avec des `ping <NOM>`

```bash
# association IP/NOM dans le fichier /etc/hosts
[roxanne@node1 ~]$ sudo nano /etc/hosts
[roxanne@node1 ~]$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.101.1.12 node2
[roxanne@node1 ~]$ ping node2
PING node2 (10.101.1.12) 56(84) bytes of data.
64 bytes from node2 (10.101.1.12): icmp_seq=1 ttl=64 time=0.571 ms
64 bytes from node2 (10.101.1.12): icmp_seq=2 ttl=64 time=0.468 ms
64 bytes from node2 (10.101.1.12): icmp_seq=3 ttl=64 time=0.483 ms
^C
--- node2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2077ms
rtt min/avg/max/mdev = 0.468/0.507/0.571/0.045 ms
```  

```bash
# association IP/NOM dans le fichier /etc/hosts
[roxanne@node2 ~]$ sudo nano /etc/hosts
[sudo] password for roxanne:
[roxanne@node2 ~]$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.101.1.11 node1
[roxanne@node2 ~]$ ping node1
PING node1 (10.101.1.11) 56(84) bytes of data.
64 bytes from node1 (10.101.1.11): icmp_seq=1 ttl=64 time=0.334 ms
64 bytes from node1 (10.101.1.11): icmp_seq=2 ttl=64 time=1.20 ms
64 bytes from node1 (10.101.1.11): icmp_seq=3 ttl=64 time=0.468 ms
^C
--- node1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2041ms
rtt min/avg/max/mdev = 0.334/0.666/1.198/0.379 ms
```

- **le pare-feu est configuré pour bloquer toutes les connexions exceptées celles qui sont nécessaires**
  - commande `firewall-cmd`

```bash
# list all ports
[roxanne@node1 ~]$ sudo firewall-cmd --list-ports
[sudo] password for roxanne:
22/tcp
```

```bash
# list all ports
[roxanne@node2 ~]$ sudo firewall-cmd --list-ports
[sudo] password for roxanne:
22/tcp
```

Pour le réseau des différentes machines (ce sont les IP qui doivent figurer sur les interfaces host-only):

| Name               | IP            |
|--------------------|---------------|
| 🖥️ `node1.tp1.b2` | `10.101.1.11` |
| 🖥️ `node2.tp1.b2` | `10.101.1.12` |
| Votre hôte         | `10.101.1.1`  |

## I. Utilisateurs

[Une section dédiée aux utilisateurs est dispo dans le mémo Linux.](../../cours/memos/commandes.md#gestion-dutilisateurs).

### 1. Création et configuration

🌞 **Ajouter un utilisateur à la machine**, qui sera dédié à son administration

- précisez des options sur la commande d'ajout pour que :
  - le répertoire home de l'utilisateur soit précisé explicitement, et se trouve dans `/home`
  - le shell de l'utilisateur soit `/bin/bash`
- prouvez que vous avez correctement créé cet utilisateur
  - et aussi qu'il a le bon shell et le bon homedir

```bash
# création de l'utilisateur toto
[roxanne@node1 ~]$ sudo useradd -m -d /home/toto -s /bin/bash toto

# définition du paswd de toto
[roxanne@node1 ~]$ sudo passwd toto
Changing password for user toto.
New password:
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:
passwd: all authentication tokens updated successfully.

# connexion en tant que toto
[roxanne@node1 ~]$ sudo su toto -
[toto@node1 roxanne]$

# déplacement et affichage du dossier de toto
[toto@node1 roxanne]$ cd
[toto@node1 ~]$ pwd
/home/toto
```

```bash
[roxanne@node2 ~]$ sudo useradd -m -d /home/toto -s /bin/bash toto
[sudo] password for roxanne:
[roxanne@node2 ~]$ sudo passwd toto
Changing password for user toto.
New password:
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:
passwd: all authentication tokens updated successfully.
[roxanne@node2 ~]$ sudo su toto -
[toto@node2 roxanne]$ cd
[toto@node2 ~]$ pwd
/home/toto
```

🌞 **Créer un nouveau groupe `admins`** qui contiendra les utilisateurs de la machine ayant accès aux droits de `root` *via* la commande `sudo`.

Pour permettre à ce groupe d'accéder aux droits `root` :

- il faut modifier le fichier `/etc/sudoers`
- on ne le modifie jamais directement à la main car en cas d'erreur de syntaxe, on pourrait bloquer notre accès aux droits administrateur
- la commande `visudo` permet d'éditer le fichier, avec un check de syntaxe avant fermeture
- ajouter une ligne basique qui permet au groupe d'avoir tous les droits (inspirez vous de la ligne avec le groupe `wheel`)

```bash
# création du groupe admins
[roxanne@node1 ~]$ sudo groupadd admins

# ajout des droits root au groupe admins
[roxanne@node1 ~]$ sudo visudo /etc/sudoers
# verification des modifications
[roxanne@node1 ~]$ sudo cat /etc/sudoers
## Sudoers allows particular users to run various commands as
[...]
%wheel  ALL=(ALL)       ALL
%admins ALL=(ALL)       ALL
[...]
```

```bash
# création du groupe admins
[roxanne@node2 ~]$ sudo groupadd admins

# ajout des droits root au groupe admins
[roxanne@node2 ~]$ sudo visudo /etc/sudoers
# verification des modifications
[roxanne@node2 ~]$ sudo cat /etc/sudoers
## Sudoers allows particular users to run various commands as
[...]
%wheel  ALL=(ALL)       ALL
%admins ALL=(ALL)       ALL
[...]
```

🌞 **Ajouter votre utilisateur à ce groupe `admins`**

> Essayez d'effectuer une commande avec `sudo` peu importe laquelle, juste pour tester que vous avez le droit d'exécuter des commandes sous l'identité de `root`. Vous pouvez aussi utiliser `sudo -l` pour voir les droits `sudo` auquel votre utilisateur courant a accès.

```bash
# toto n'a pas le droit d'éxecuter des commandes sous l'identité de root
[toto@node1 ~]$ sudo -l
[sudo] password for toto:
Sorry, user toto may not run sudo on node1.
```

```bash
# toto n'a pas le droit d'éxecuter des commandes sous l'identité de root
[toto@node2 ~]$ sudo -l
[sudo] password for toto:
Sorry, user toto may not run sudo on node2.
```

```bash
# ajout de toto au groupe admins
[roxanne@node1 ~]$ sudo usermod -a -G admins toto
[roxanne@node1 ~]$ sudo su toto -

# toto a le droit d'éxecuter des commandes sous l'identité de root
[toto@node1 roxanne]$ sudo -l
[sudo] password for toto:
Matching Defaults entries for toto on node1:
    !visiblepw, always_set_home, match_group_by_gid,
    always_query_group_plugin, env_reset, env_keep="COLORS DISPLAY HOSTNAME
    HISTSIZE KDEDIR LS_COLORS", env_keep+="MAIL PS1 PS2 QTDIR USERNAME LANG
    LC_ADDRESS LC_CTYPE", env_keep+="LC_COLLATE LC_IDENTIFICATION
    LC_MEASUREMENT LC_MESSAGES", env_keep+="LC_MONETARY LC_NAME LC_NUMERIC
    LC_PAPER LC_TELEPHONE", env_keep+="LC_TIME LC_ALL LANGUAGE LINGUAS
    _XKB_CHARSET XAUTHORITY", secure_path=/sbin\:/bin\:/usr/sbin\:/usr/bin

User toto may run the following commands on node1:
    (ALL) ALL
```

```bash
# ajout de toto au groupe admins
[roxanne@node2 ~]$ sudo usermod -a -G admins toto
[roxanne@node2 ~]$ sudo su toto -

# toto a le droit d'éxecuter des commandes sous l'identité de root
[toto@node2 roxanne]$ sudo -l
[sudo] password for toto:
Matching Defaults entries for toto on node1:
    !visiblepw, always_set_home, match_group_by_gid,
    always_query_group_plugin, env_reset, env_keep="COLORS DISPLAY HOSTNAME
    HISTSIZE KDEDIR LS_COLORS", env_keep+="MAIL PS1 PS2 QTDIR USERNAME LANG
    LC_ADDRESS LC_CTYPE", env_keep+="LC_COLLATE LC_IDENTIFICATION
    LC_MEASUREMENT LC_MESSAGES", env_keep+="LC_MONETARY LC_NAME LC_NUMERIC
    LC_PAPER LC_TELEPHONE", env_keep+="LC_TIME LC_ALL LANGUAGE LINGUAS
    _XKB_CHARSET XAUTHORITY", secure_path=/sbin\:/bin\:/usr/sbin\:/usr/bin

User toto may run the following commands on node2:
    (ALL) ALL
```

---

1. Utilisateur créé et configuré
2. Groupe `admins` créé
3. Groupe `admins` ajouté au fichier `/etc/sudoers`
4. Ajout de l'utilisateur au groupe `admins`

### 2. SSH

[Une section dédiée aux clés SSH existe dans le cours.](../../cours/SSH/README.md)

Afin de se connecter à la machine de façon plus sécurisée, on va configurer un échange de clés SSH lorsque l'on se connecte à la machine.

🌞 **Pour cela...**

- il faut générer une clé sur le poste client de l'administrateur qui se connectera à distance (vous :) )
  - génération de clé depuis VOTRE poste donc
  - sur Windows, on peut le faire avec le programme `puttygen.exe` qui est livré avec `putty.exe`
- déposer la clé dans le fichier `/home/<USER>/.ssh/authorized_keys` de la machine que l'on souhaite administrer
  - vous utiliserez l'utilisateur que vous avez créé dans la partie précédente du TP
  - on peut le faire à la main
  - ou avec la commande `ssh-copy-id`

```bash
# création du fichier .ssh
[toto@node1 ~]$ mkdir .ssh
[toto@node1 ~]$ ls
[toto@node1 ~]$ ls -a
.  ..  .bash_history  .bash_logout  .bash_profile  .bashrc  .ssh
```

```bash
# création du fichier .ssh
[toto@node2 ~]$ mkdir .ssh
[toto@node2 ~]$ ls
[toto@node2 ~]$ ls -a
.  ..  .bash_history  .bash_logout  .bash_profile  .bashrc  .ssh
```

```bash
  ~    cat ~/.ssh/id_rsa.pub | ssh toto@10.101.1.11 "cat >> ~/.ssh/aut
horized_keys"
toto@10.101.1.11's password:
```

```bash
  ~    cat ~/.ssh/id_rsa.pub | ssh toto@10.101.1.12 "cat >> ~/.ssh/aut
horized_keys"
toto@10.101.1.12's password:
```

```bash
# vérification de la clé
[toto@node1 ~]$ cd .ssh/
[toto@node1 .ssh]$ cat authorized_keys
ssh-rsa [...]
```

```bash
# vérification de la clé
[toto@node2 ~]$ cd .ssh/
[toto@node2 .ssh]$ cat authorized_keys
ssh-rsa [...]
```

🌞 **Assurez vous que la connexion SSH est fonctionnelle**, sans avoir besoin de mot de passe.

```bash
# connexion à la machine en ssh
  ~    ssh toto@10.101.1.11
toto@10.101.1.11's password:
Last login: Mon Nov 14 15:10:29 2022 from 10.101.1.1
[toto@node1 ~]$
```

```bash
# connexion à la machine en ssh
  ~    ssh toto@10.101.1.12
toto@10.101.1.12's password:
Last login: Mon Nov 14 15:10:29 2022 from 10.101.1.1
[toto@node2 ~]$
```

## II. Partitionnement

[Il existe une section dédiée au partitionnement dans le cours](../../cours/part/)

### 1. Préparation de la VM

⚠️ **Uniquement sur `node1.tp1.b2`.**

Ajout de deux disques durs à la machine virtuelle, de 3Go chacun.

### 2. Partitionnement

⚠️ **Uniquement sur `node1.tp1.b2`.**

🌞 **Utilisez LVM** pour...

- agréger les deux disques en un seul *volume group*

```bash
# création du premier PV
[toto@node1 ~]$ sudo pvcreate /dev/sdb
[sudo] password for toto:
  Physical volume "/dev/sdb" successfully created.

# vérification
[toto@node1 ~]$ sudo pvs
  Devices file sys_wwid t10.ATA_____VBOX_HARDDISK___________________________VB8ca9e004-08774154_ PVID b1M3xdUOQmI7xvH15VvjrwSBQAjoWM8U last seen on /dev/sda2 not found.
  PV         VG Fmt  Attr PSize PFree
  /dev/sdb      lvm2 ---  3.00g 3.00g

# création du second PV
[toto@node1 ~]$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.

# vérification
[toto@node1 ~]$ sudo pvs
  Devices file sys_wwid t10.ATA_____VBOX_HARDDISK___________________________VB8ca9e004-08774154_ PVID b1M3xdUOQmI7xvH15VvjrwSBQAjoWM8U last seen on /dev/sda2 not found.
  PV         VG Fmt  Attr PSize PFree
  /dev/sdb      lvm2 ---  3.00g 3.00g
  /dev/sdc      lvm2 ---  3.00g 3.00g
```

```bash
# création du VG
[toto@node1 ~]$ sudo vgcreate vg0 /dev/sdb /dev/sdc
[sudo] password for toto:
  Volume group "vg0" successfully created

# vérification
[toto@node1 ~]$ sudo vgs
  Devices file sys_wwid t10.ATA_____VBOX_HARDDISK___________________________VB8ca9e004-08774154_ PVID b1M3xdUOQmI7xvH15VvjrwSBQAjoWM8U last seen on /dev/sda2 not found.
  VG  #PV #LV #SN Attr   VSize VFree
  vg0   2   0   0 wz--n- 5.99g 5.99g
[toto@node1 ~]$ sudo vgdisplay
  Devices file sys_wwid t10.ATA_____VBOX_HARDDISK___________________________VB8ca9e004-08774154_ PVID b1M3xdUOQmI7xvH15VvjrwSBQAjoWM8U last seen on /dev/sda2 not found.
  --- Volume group ---
  VG Name               vg0
  System ID
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  [...]
  Cur PV                2
  Act PV                2
  VG Size               5.99 GiB
  PE Size               4.00 MiB
  Total PE              1534
  Alloc PE / Size       0 / 0
  Free  PE / Size       1534 / 5.99 GiB
  VG UUID               ejH5rf-p0KP-NIpw-00le-CS69-dFLW-nfoCND

```

- créer 3 *logical volumes* de 1 Go chacun

```bash
# création des LV
[toto@node1 ~]$ sudo lvcreate -L 1G vg0 -n lv0
  Logical volume "lv0" created.
[toto@node1 ~]$ sudo lvcreate -L 1G vg0 -n lv1
  Logical volume "lv1" created.
[toto@node1 ~]$ sudo lvcreate -L 1G vg0 -n lv2
  Logical volume "lv2" created.

# vérification  
[toto@node1 ~]$ sudo lvs
  Devices file sys_wwid t10.ATA_____VBOX_HARDDISK___________________________VB8ca9e004-08774154_ PVID b1M3xdUOQmI7xvH15VvjrwSBQAjoWM8U last seen on /dev/sda2 not found.
  LV   VG  Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv0  vg0 -wi-a----- 1.00g

  lv1  vg0 -wi-a----- 1.00g

  lv2  vg0 -wi-a----- 1.00g

[toto@node1 ~]$ sudo lvdisplay
  Devices file sys_wwid t10.ATA_____VBOX_HARDDISK___________________________VB8ca9e004-08774154_ PVID b1M3xdUOQmI7xvH15VvjrwSBQAjoWM8U last seen on /dev/sda2 not found.
  --- Logical volume ---
  LV Path                /dev/vg0/lv0
  LV Name                lv0
  VG Name                vg0
  [...]
  LV Size                1.00 GiB
  Current LE             256
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:2

  --- Logical volume ---
  LV Path                /dev/vg0/lv1
  LV Name                lv1
  VG Name                vg0
  [...]
  LV Size                1.00 GiB
  Current LE             256
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:3

  --- Logical volume ---
  LV Path                /dev/vg0/lv2
  LV Name                lv2
  VG Name                vg0
  [...]
  LV Size                1.00 GiB
  Current LE             256
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:4
```

- formater ces partitions en `ext4`

```bash
# formatage des LV
[toto@node1 ~]$ sudo mkfs -t ext4 /dev/vg0/lv0
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: ed5fe08e-ca3c-487a-a322-aa72349f8153
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done

[toto@node1 ~]$ sudo mkfs -t ext4 /dev/vg0/lv1
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: af7658a8-b321-4880-b952-867b4168862f
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done

[toto@node1 ~]$ sudo mkfs -t ext4 /dev/vg0/lv2
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: a9b5fe1c-033b-4e04-9c04-ff4115193d43
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```

- monter ces partitions pour qu'elles soient accessibles aux points de montage `/mnt/part1`, `/mnt/part2` et `/mnt/part3`.

```bash
# montage des LV
[toto@node1 ~]$ sudo mkdir /mnt/part1
[toto@node1 ~]$ sudo mount /dev/vg0/lv0 /mnt/part1
[toto@node1 ~]$ sudo mkdir /mnt/part2
[toto@node1 ~]$ sudo mount /dev/vg0/lv0 /mnt/part2
[toto@node1 ~]$ sudo mkdir /mnt/part3
[toto@node1 ~]$ sudo mount /dev/vg0/lv0 /mnt/part3

# vérification
[toto@node1 ~]$ sudo mount
[...]
/dev/mapper/vg0-lv0 on /mnt/part1 type ext4 (rw,relatime,seclabel)
/dev/mapper/vg0-lv1 on /mnt/part2 type ext4 (rw,relatime,seclabel)
/dev/mapper/vg0-lv2 on /mnt/part3 type ext4 (rw,relatime,seclabel)

[toto@node1 ~]$ df -h
Filesystem           Size  Used Avail Use% Mounted on
devtmpfs             461M     0  461M   0% /dev
tmpfs                481M     0  481M   0% /dev/shm
tmpfs                193M  3.0M  190M   2% /run
/dev/mapper/rl-root  6.2G  998M  5.3G  16% /
/dev/sda1           1014M  166M  849M  17% /boot
tmpfs                 97M     0   97M   0% /run/user/1001
/dev/mapper/vg0-lv0  974M   24K  907M   1% /mnt/part1
/dev/mapper/vg0-lv1  974M   24K  907M   1% /mnt/part2
/dev/mapper/vg0-lv2  974M   24K  907M   1% /mnt/part3
```

🌞 **Grâce au fichier `/etc/fstab`**, faites en sorte que cette partition soit montée automatiquement au démarrage du système.

```bash
# montage automatique des partitions
[toto@node1 ~]$ sudo nano /etc/fstab
[toto@node1 ~]$ cat /etc/fstab
[...]
/dev/vg0/lv0 /mnt/part1 ext4 defaults 0 0
/dev/vg0/lv1 /mnt/part2 ext4 defaults 0 0
/dev/vg0/lv2 /mnt/part3 ext4 defaults 0 0
```

```bash
# démontage de la partition
[toto@node1 ~]$ sudo umount /mnt/part1
[toto@node1 ~]$ sudo umount /mnt/part2
[toto@node1 ~]$ sudo umount /mnt/part3
```

```bash
# vérification du montage automatique
[toto@node1 ~]$ sudo mount -av
[...]
mount: /mnt/part1 does not contain SELinux labels.
       You just mounted a file system that supports labels which does not
       contain labels, onto an SELinux box. It is likely that confined
       applications will generate AVC messages and not be allowed access to
       this file system.  For more details see restorecon(8) and mount(8).
/mnt/part1               : successfully mounted
mount: /mnt/part2 does not contain SELinux labels.
       You just mounted a file system that supports labels which does not
       contain labels, onto an SELinux box. It is likely that confined
       applications will generate AVC messages and not be allowed access to
       this file system.  For more details see restorecon(8) and mount(8).
/mnt/part2               : successfully mounted
mount: /mnt/part3 does not contain SELinux labels.
       You just mounted a file system that supports labels which does not
       contain labels, onto an SELinux box. It is likely that confined
       applications will generate AVC messages and not be allowed access to
       this file system.  For more details see restorecon(8) and mount(8).
/mnt/part3               : successfully mounted
```

✨**Bonus** : amusez vous avez les options de montage. Quelques options intéressantes :

- `noexec`
- `ro`
- `user`
- `nosuid`
- `nodev`
- `protect`

## III. Gestion de services

Au sein des systèmes GNU/Linux les plus utilisés, c'est *systemd* qui est utilisé comme gestionnaire de services (entre autres).

Pour manipuler les services entretenus par *systemd*, on utilise la commande `systemctl`.

On peut lister les unités `systemd` actives de la machine `systemctl list-units -t service`.

**Référez-vous au mémo pour voir les autres commandes `systemctl` usuelles.**

## 1. Interaction avec un service existant

⚠️ **Uniquement sur `node1.tp1.b2`.**

Parmi les services système déjà installés sur Rocky, il existe `firewalld`. Cet utilitaire est l'outil de firewalling de Rocky.

🌞 **Assurez-vous que...**

- l'unité est démarrée
- l'unitée est activée (elle se lance automatiquement au démarrage)

```bash
[toto@node2 ~]$ sudo systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; ve>
     Active: active (running) since Mon 2022-11-14 19:31:44 CET; 1h 50min a>
       Docs: man:firewalld(1)
   Main PID: 639 (firewalld)
      Tasks: 2 (limit: 5896)
     Memory: 40.8M
        CPU: 530ms
     CGroup: /system.slice/firewalld.service
             └─639 /usr/bin/python3 -s /usr/sbin/firewalld --nofork --nopid
    [...]
```

## 2. Création de service

![Création de service systemd](./pics/create_service.png)

### A. Unité simpliste

⚠️ **Uniquement sur `node1.tp1.b2`.**

🌞 **Créer un fichier qui définit une unité de service** 

- le fichier `web.service`
- dans le répertoire `/etc/systemd/system`

Déposer le contenu suivant :

```
[Unit]
Description=Very simple web service

[Service]
ExecStart=/bin/python3 -m http.server 8888

[Install]
WantedBy=multi-user.target
```

```bash
# création du service
[toto@node2 ~]$ sudo nano /etc/systemd/system/web.service
[sudo] password for toto:
[toto@node2 ~]$ cat /etc/systemd/system/web.service
[Unit]
Description=Very simple web service

[Service]
ExecStart=/bin/python3 -m http.server 8888

[Install]
WantedBy=multi-user.target
```

Le but de cette unité est de lancer un serveur web sur le port 8888 de la machine. **N'oubliez pas d'ouvrir ce port dans le firewall.**

```bash
# ouverture du port
[toto@node2 ~]$ sudo firewall-cmd --add-port=8888/tcp --permanent
success
[toto@node2 ~]$ sudo firewall-cmd --reload
success
```

Une fois l'unité de service créée, il faut demander à *systemd* de relire les fichiers de configuration :

```bash
$ sudo systemctl daemon-reload
```

```bash
# relecture des fichiers de configuration
[toto@node2 ~]$ sudo systemctl daemon-reload
```

Enfin, on peut interagir avec notre unité :

```bash
$ sudo systemctl status web
$ sudo systemctl start web
$ sudo systemctl enable web
```

```bash
# affichage du statut du service
[toto@node2 ~]$ sudo systemctl status web
○ web.service - Very simple web service
     Loaded: loaded (/etc/systemd/system/web.service; disabled; vendor pres>
     Active: inactive (dead)

# lancement du service
[toto@node2 ~]$ sudo systemctl start web
[toto@node2 ~]$ sudo systemctl enable web
Created symlink /etc/systemd/system/multi-user.target.wants/web.service → /etc/systemd/system/web.service.

# vérification du statut du service
[toto@node2 ~]$ sudo systemctl status web
● web.service - Very simple web service
     Loaded: loaded (/etc/systemd/system/web.service; enabled; vendor prese>
     Active: active (running) since Mon 2022-11-14 21:47:23 CET; 10s ago
   Main PID: 1105 (python3)
      Tasks: 1 (limit: 5896)
     Memory: 9.2M
        CPU: 104ms
     CGroup: /system.slice/web.service
             └─1105 /bin/python3 -m http.server 8888
```

🌞 **Une fois le service démarré, assurez-vous que pouvez accéder au serveur web**

- avec un navigateur depuis votre PC
- ou la commande `curl` depuis l'autre machine (je veux ça dans le compte-rendu :3)
- sur l'IP de la VM, port 8888

```bash
# accès au serveur web
[toto@node1 ~]$ curl 10.101.1.12:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="afs/">afs/</a></li>
<li><a href="bin/">bin@</a></li>
<li><a href="boot/">boot/</a></li>
<li><a href="dev/">dev/</a></li>
<li><a href="etc/">etc/</a></li>
<li><a href="home/">home/</a></li>
<li><a href="lib/">lib@</a></li>
<li><a href="lib64/">lib64@</a></li>
<li><a href="media/">media/</a></li>
<li><a href="mnt/">mnt/</a></li>
<li><a href="opt/">opt/</a></li>
<li><a href="proc/">proc/</a></li>
<li><a href="root/">root/</a></li>
<li><a href="run/">run/</a></li>
<li><a href="sbin/">sbin@</a></li>
<li><a href="srv/">srv/</a></li>
<li><a href="sys/">sys/</a></li>
<li><a href="tmp/">tmp/</a></li>
<li><a href="usr/">usr/</a></li>
<li><a href="var/">var/</a></li>
</ul>
<hr>
</body>
</html>
```

### B. Modification de l'unité

🌞 **Préparez l'environnement pour exécuter le mini serveur web Python**

- créer un utilisateur `web`
- créer un dossier `/var/www/meow/`
- créer un fichier dans le dossier `/var/www/meow/` (peu importe son nom ou son contenu, c'est pour tester)
- montrez à l'aide d'une commande les permissions positionnées sur le dossier et son contenu

> Pour que tout fonctionne correctement, il faudra veiller à ce que le dossier et le fichier appartiennent à l'utilisateur `web` et qu'il ait des droits suffisants dessus.

🌞 **Modifiez l'unité de service `web.service` créée précédemment en ajoutant les clauses**

- `User=` afin de lancer le serveur avec l'utilisateur `web` dédié
- `WorkingDirectory=` afin de lancer le serveur depuis le dossier créé au dessus : `/var/www/meow/`
- ces deux clauses sont à positionner dans la section `[Service]` de votre unité

🌞 **Vérifiez le bon fonctionnement avec une commande `curl`**
