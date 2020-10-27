#!/bin/bash

cd "$(dirname "$0")"

#variables  mySQL credentials...use certificates in next version
SQLsrv=''
SQLusr=""
SQLpwd=""
SQLdbs=""
SQL_log="./mysql-log.txt"   #status log -
Timestamp=$(date +"%Y-%m-%d-%H-%M")   #separate logfile every day

#Now cycle through all SQL files and process them with mySQL
FILES=./dumps/adsb*sql
for f in $FILES
do
  #echo "Processing $f file..."
  #ls -ls $f
  Timestamp=$(date +"%Y-%m-%d-%H-%M")
  #now check if file is old enough to touch
  if [[ $(find $f -mmin +1) != "" ]]
        then #file found that is older as one minute
        #echo "old $f"
        #now launch SQL command
        SQLout=$(mysql -h $SQLsrv -u $SQLusr -p$SQLpwd $SQLdbs <$f 2>&1)
        SQLerr=$?
        if [ $SQLerr != 0 ];
                then  #SQL error
                echo "Error in $f with $SQLout" >>$SQL_log
                cp $f ./dumps/error/ #copy the error SQL file
                rm $f  #delete the original file
                else
                echo "Successfully Processed $f" >>$SQL_log
                rm $f   #delete SQL file
                fi  #SQL error
        else #file is fresh - dont touch it
        echo "Ignored fresh file $f" >>$SQL_log
        fi #find mmin1 - check for file age

done