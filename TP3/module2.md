# Module 2 : Réplication de base de données

Il y a plein de façons de mettre en place de la réplication de base données de type MySQL (comme MariaDB).

MariaDB possède un mécanisme de réplication natif qui peut très bien faire l'affaire pour faire des tests comme les nôtres.

Une réplication simple est une configuration de type "master-slave". Un des deux serveurs est le *master* l'autre est un *slave*.

Le *master* est celui qui reçoit les requêtes SQL (des applications comme NextCloud) et qui les traite.

Le *slave* ne fait que répliquer les donneés que le *master* possède.

La [doc officielle de MariaDB](https://mariadb.com/kb/en/setting-up-replication/) ou encore [cet article cool](https://cloudinfrastructureservices.co.uk/setup-mariadb-replication/) expose de façon simple comment mettre en place une telle config.

Pour ce module, vous aurez besoin d'un deuxième serveur de base de données.

✨ **Bonus** : Faire en sorte que l'utilisateur créé en base de données ne soit utilisable que depuis l'autre serveur de base de données

- inspirez-vous de la création d'utilisateur avec `CREATE USER` effectuée dans le TP2

✨ **Bonus** : Mettre en place un setup *master-master* où les deux serveurs sont répliqués en temps réel, mais les deux sont capables de traiter les requêtes.


```sh
# installation sur le deuxième serveur de MariaDB
[roxanne@replication ~]$ sudo dnf install mariadb-server -y
[sudo] password for roxanne:
[...]
Complete!

[roxanne@replication ~]$ sudo systemctl start mariadb
[roxanne@replication ~]$ sudo systemctl enable mariadb
Created symlink /etc/systemd/system/mysql.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/mysqld.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/multi-user.target.wants/mariadb.service → /usr/lib/systemd/system/mariadb.service.
```

```sh
[roxanne@replication ~]$ sudo mysql_secure_installation

[...]

Remove anonymous users? [Y/n]
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n]
 ... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n]
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n]
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```

```sh
# modification du fichier de configuration du master de la réplication
[roxanne@db ~]$ sudo nano /etc/my.cnf
[sudo] password for roxanne:
[roxanne@db ~]$ cat /
afs/   boot/  etc/   lib/   media/ opt/   root/  sbin/  sys/   usr/
bin/   dev/   home/  lib64/ mnt/   proc/  run/   srv/   tmp/   var/
[roxanne@db ~]$ cat /etc/my.cnf
#
# This group is read both both by the client and the server
# use it for options that affect everything
#
[client-server]

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d

[mariadb]
log-bin
server_id=1
log-basename=master1
binlog-format=mixed
skip-networking=0
bind-address=0.0.0.0
```

```sh
# relance du service MariaDB
[roxanne@db ~]$ sudo systemctl restart mariadb
```

```sql
[roxanne@db ~]$ sudo mysql -u root -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 5
Server version: 10.5.16-MariaDB-log MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE USER 'replication'@'10.102.1.14' identified by 'toto';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT REPLICATION SLAVE ON *.* TO 'replication'@'10.102.1.
14';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> SHOW MASTER STATUS;
+--------------------+----------+--------------+------------------+
| File               | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+--------------------+----------+--------------+------------------+
| master1-bin.000001 |      798 |              |                  |
+--------------------+----------+--------------+------------------+
1 row in set (0.000 sec)

MariaDB [(none)]> EXIT;
Bye
```

```sh
# au dessus
# création d'un utilisateur pour la réplication
# et attribution des droits
```

```sh
# modification du fichier de configuration du slave de la réplication
[roxanne@replication ~]$ sudo nano /etc/my.cnf
[roxanne@replication ~]$ cat /etc/my.cnf
#
# This group is read both both by the client and the server
# use it for options that affect everything
#
[client-server]

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d

[mariadb]
log-bin
server_id=2
log-basename=master2
binlog-format=mixed
skip-networking=0
bind-address=0.0.0.0
```

```sh
# relance du service MariaDB
[roxanne@replication ~]$ sudo systemctl restart mariadb
[sudo] password for roxanne:
```

```sql
[roxanne@replication ~]$ sudo mysql -u root -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 4
Server version: 10.5.16-MariaDB-log MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> STOP SLAVE;
Query OK, 0 rows affected, 1 warning (0.000 sec)

MariaDB [(none)]> CHANGE MASTER TO MASTER_HOST='10.102.1.12', MASTER_USER = 'replication', MASTER_PASSWORD='toto', MASTER_LOG_FILE = 'master1-bin.000002', MASTER_LOG_POS = 344;
Query OK, 0 rows affected (0.011 sec)

MariaDB [(none)]> START SLAVE;
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> EXIT;
Bye
```

```sh
# au dessus
# arrêt du slave lancé par defaut
# configuration du slave pour répliquer le master
```

```sql
[roxanne@db ~]$ sudo mysql -u root -p
[sudo] password for roxanne:
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 7
Server version: 10.5.16-MariaDB-log MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE DATABASE schooldb;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> USE schooldb;
Database changed
MariaDB [schooldb]> CREATE TABLE students(id int, name va
rchar(20), surname varchar(20));
Query OK, 0 rows affected (0.012 sec)

MariaDB [schooldb]> INSERT INTO students VALUES (1, "hite
sh", "jethva");
Query OK, 1 row affected (0.004 sec)

MariaDB [schooldb]> INSERT INTO students VALUES (2, "jaye
sh", "jethva");
Query OK, 1 row affected (0.004 sec)

MariaDB [schooldb]> SELECT * FROM students;
+------+--------+---------+
| id   | name   | surname |
+------+--------+---------+
|    1 | hitesh | jethva  |
|    2 | jayesh | jethva  |
+------+--------+---------+
2 rows in set (0.001 sec)
```

```sh
# au dessus
# création d'une base de données
# switch sur cette db
# création d'une table
# insertion de données
# vérification des données
```

```sql
MariaDB [(none)]> SHOW SLAVE STATUS \G;
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 10.102.1.12
                   Master_User: replication
                   Master_Port: 3306
                 Connect_Retry: 60
               Master_Log_File: master1-bin.000002
           Read_Master_Log_Pos: 616
                Relay_Log_File: master2-relay-bin.000002
                 Relay_Log_Pos: 829
         Relay_Master_Log_File: master1-bin.000002
              Slave_IO_Running: Yes
             Slave_SQL_Running: Yes
               Replicate_Do_DB:
           Replicate_Ignore_DB:
            Replicate_Do_Table:
        Replicate_Ignore_Table:
       Replicate_Wild_Do_Table:
   Replicate_Wild_Ignore_Table:
                    Last_Errno: 0
                    Last_Error:
                  Skip_Counter: 0
           Exec_Master_Log_Pos: 616
               Relay_Log_Space: 1140
               Until_Condition: None
                Until_Log_File:
                 Until_Log_Pos: 0
            Master_SSL_Allowed: No
            Master_SSL_CA_File:
            Master_SSL_CA_Path:
               Master_SSL_Cert:
             Master_SSL_Cipher:
                Master_SSL_Key:
         Seconds_Behind_Master: 0
 Master_SSL_Verify_Server_Cert: No
                 Last_IO_Errno: 0
                 Last_IO_Error:
                Last_SQL_Errno: 0
                Last_SQL_Error:
   Replicate_Ignore_Server_Ids:
              Master_Server_Id: 1
                Master_SSL_Crl:
            Master_SSL_Crlpath:
                    Using_Gtid: No
                   Gtid_IO_Pos:
       Replicate_Do_Domain_Ids:
   Replicate_Ignore_Domain_Ids:
                 Parallel_Mode: optimistic
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
              Slave_DDL_Groups: 2
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
1 row in set (0.000 sec)

ERROR: No query specified

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| test_rep           |
+--------------------+
4 rows in set (0.000 sec)
```

```sh
# au dessus
# vérification de la réplication
```