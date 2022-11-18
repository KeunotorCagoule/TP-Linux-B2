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
name='$db'_'$datesauv'
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