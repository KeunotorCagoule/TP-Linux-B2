#!/bin/bash
# Last Update : 18/11/2022
# Written by : Roulland Roxanne
# This script will dump the database and save it to a file

# Set the variables
user='restore'
passwd='toto'
db='nextcloud'
ip_serv='localhost'
datesauv=$(date '+%y%m%d_%H%M%S')
name='${db}_${datesauv}'
outputpath="/srv/db_dumps/${name}.sql"

# Dump the database

echo "Backup started for database - ${db}."
mysqldump -h ${ip_serv} -u ${user} -p${passwd} --skip-lock-tables --databases ${db} > $outputpath
if [[ $? == 0 ]]
then
        gzip -c $outputpath > '${outputpath}.gz'
        rm -f $outputpath
        echo "Backup successfully completed."
else 
        echo "Backup failed."
        rm -f outputpath
        exit 1
fi
