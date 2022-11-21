# Module 5 : Monitoring

Dans ce sujet on va installer un outil plutôt clé en main pour mettre en place un monitoring simple de nos machines.

L'outil qu'on va utiliser est [Netdata](https://learn.netdata.cloud/docs/agent/packaging/installer/methods/kickstart).

➜ **Je vous laisse suivre la doc pour le mettre en place** [ou ce genre de lien](https://wiki.crowncloud.net/?How_to_Install_Netdata_on_Rocky_Linux_9). Vous n'avez pas besoin d'utiliser le "Netdata Cloud" machin truc. Faites simplement une install locale.

Installez-le sur `web.tp2.linux` et `db.tp2.linux`.

Une fois en place, Netdata déploie une interface un Web pour avoir moult stats en temps réel, utilisez une commande `ss` pour repérer sur quel port il tourne.

Utilisez votre navigateur pour visiter l'interface web de Netdata `http://<IP_VM>:<PORT_NETDATA>`.

```sh
# installation de netdata
[/tmp/netdata-kickstart-pzwHT0dR6k]$ sudo env dnf install netdata
[...]

Complete!
 OK

[...]
```

```sh
# lancement du service netdata
[roxanne@web ~]$ sudo systemctl start netdata
[sudo] password for roxanne:
[roxanne@web ~]$ sudo systemctl enable netdata
[roxanne@web ~]$ sudo systemctl status netdata
● netdata.service - Real time performance monitoring
     Loaded: loaded (/usr/lib/systemd/system/netdata.service; enabled; vend>
     Active: active (running) since Mon 2022-11-21 11:06:41 CET; 5min ago
   Main PID: 1597 (netdata)
      Tasks: 61 (limit: 5896)
     Memory: 89.8M
        CPU: 9.603s
     CGroup: /system.slice/netdata.service
             ├─1597 /usr/sbin/netdata -P /run/netdata/netdata.pid -D
             ├─1599 /usr/sbin/netdata --special-spawn-server
             ├─1800 bash /usr/libexec/netdata/plugins.d/tc-qos-helper.sh 1
             ├─1806 /usr/libexec/netdata/plugins.d/apps.plugin 1
             └─1810 /usr/libexec/netdata/plugins.d/go.d.plugin 1
[...]
```

```sh
# vérification du port d'écoute, celui de netdata est 19999
[roxanne@web ~]$ sudo ss -laptn | grep netdata
LISTEN    0      4096            127.0.0.1:8125             0.0.0.0:*     users:(("netdata",pid=1597,fd=67))

LISTEN    0      4096              0.0.0.0:19999            0.0.0.0:*     users:(("netdata",pid=1597,fd=6))

LISTEN    0      4096                [::1]:8125                [::]:*     users:(("netdata",pid=1597,fd=66))

LISTEN    0      4096                 [::]:19999               [::]:*     users:(("netdata",pid=1597,fd=7))
```

```sh
# ouverture du port 19999 dans le firewall
[roxanne@web ~]$ sudo firewall-cmd --add-port=19999/tcp --permanent
success
[roxanne@web ~]$ sudo firewall-cmd --reload
success
```

➜ **Configurer Netdata pour qu'il vous envoie des alertes** dans [un salon Discord](https://learn.netdata.cloud/docs/agent/health/notifications/discord) dédié en cas de soucis

```sh
# création du fichier de configuration pour les alertes
[roxanne@web netdata]$ sudo touch health.d/cpu_usage.conf
[sudo] password for roxanne:
```

```sh
# modification du fichier de configuration pour les alertes
[roxanne@web netdata]$ sudo ./edit-config health.d/cpu_usage.conf
Editing '/etc/netdata/health.d/cpu_usage.conf' ...
[roxanne@web netdata]$ cat health.d/cpu_usage.conf
alarm: cpu_usage
on: system.cpu
lookup: average -3s percentage foreach user,system
units: %
every: 10s
warn: $this > 50
crit: $this > 80
info: CPU utilization of users or the system itself
```

```sh
# lancement des alarmes
[roxanne@web netdata]$ sudo netdatacli reload-health
[sudo] password for roxanne:
```

```sh
# création du webhook pour les alertes
[roxanne@web netdata]$ sudo /etc/netdata/edit-config health_alarm_notify.conf
Editing '/etc/netdata/health_alarm_notify.conf' ...
[roxanne@web netdata]$ cat health_alarm_notify.conf | grep DISCORD
SEND_DISCORD="YES"
DISCORD_WEBHOOK_URL=""https://discord.com/api/webhooks/1044203512931827753/FexqqAK_Ez42Z0gIj3ZkOZIciVd47w09lYenvV2D5PiNPupbo88aHGJEGA-62tdvIsqs
DEFAULT_RECIPIENT_DISCORD="alarme-cpu"
```

➜ **Vérifier que les alertes fonctionnent** en surchargeant volontairement la machine par exemple (effectuez des *stress tests* de RAM et CPU, ou remplissez le disque volontairement par exemple)

```sh
# vérification des alertes avec un stress test de la RAM
[roxanne@web netdata]$ sudo dnf install stress-ng -y
[...]

Complete!

[roxanne@web netdata]$ sudo stress-ng -c 10 -l 60
stress-ng: info:  [3036] defaulting to a 86400 second (1 day, 0.00 secs) run per stressor
stress-ng: info:  [3036] dispatching hogs: 10 cpu
^Cstress-ng: info:  [3036] successful run completed in 17.76s
```

```sh
les alertes fonctionnent bien :)
```


![Monitoring](../pics/monit.jpg)
