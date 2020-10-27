#!/bin/bash

cd "$(dirname "$0")"

#Shell script to listen parse and aggregate ADSB data
#Run in foreground to see progress bar
#run  in background with: Dump2sql.sh >/dev/null &

#variables DUMP1090 server
ADSBhost=""
ADSBport="30003"
#now declare the arrays
counter=0  #for loop control
declare -a arr_call    #collect call_signs per aircraft
declare -a arr_alti    #collect altitude per aircraft
declare -a arr_sped    #collect groundspeed per aircraft
declare -a arr_trck    #collect track per aircraft
declare -a arr_vert    #collect vertical speed per aircraft
declare -a arr_lat    #collect latitude per aircraft
declare -a arr_lon    #collect longitude per aircraft
declare -a arr_last_position    #collect of last positions per aircraft
#variables-logfiles
TimestampDaily=$(date +"%Y-%m-%d")        #separate logfile every day
TimestampMinut=$(date +"%Y-%m-%d-%H-%M")   #separate SQL file every minute
ADSB_log="./adsb-log.txt"   #status log -
ADSB_sql="./dumps/adsb-sql-"   #SQL statements - append TimestampMinut

#Startup Messages
echo "DUMP1090 to MySQL By Valentin Giselbrecht (based by Matthias Gemelli)"
echo "Listening to DUMP1090 on $ADSBhost port $ADSBport"
echo "Writing Logs to $ADSB_log"
echo "--------------------------------"

#Startup log
Timestamp=$(date +"%Y-%m-%d %H:%M:%S")
echo "Dump2SQL launched with PID $$ at $Timestamp" >> $ADSB_log

#----------------------LOOP starts------------------------
while true; do #outer loop - because netcat stops too often with Dump1090 mutability
#inner loop - netcat listener
nc -d $ADSBhost $ADSBport | while IFS="," read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22
do     #loop until a break is thrown or netcat stops

#first update the timestamp for log files
TimestampDaily=$(date +"%Y-%m-%d")        #separate logfile every day
TimestampMinut=$(date +"%Y-%m-%d-%H-%M")  #separate SQL file every minute

#relevant data fields in every ADSB record
#echo "Field 05 HexIdent         :$f5"
#echo "Field 07 Date message gen :$f7"
#echo "Field 08 Time message gen :$f8"
#echo "Field 11 Callsign         :$f11"
#echo "Field 12 Altitude         :$f12"
#echo "Field 13 GroundSpeed      :$f13"
#echo "Field 14 Track            :$f14"
#echo "Field 15 Latitude         :$f15"
#echo "Field 16 Longitude        :$f16"
#echo "Field 17 Vertical Rate    :$f17"

#now save the data into array, using HexIdent as index
#overwrite only if field is not empty
ident=$((0x${f5}))   #convert hex to decimal
if [ "$f11" != "" ];  then arr_call[ident]="$f11"; fi
if [ "$f12" != "" ];  then arr_alti[ident]="$f12"; fi
if [ "$f13" != "" ];  then arr_velo[ident]="$f13"; fi
if [ "$f14" != "" ];  then arr_trck[ident]="$f14"; fi
if [ "$f15" != "" ];  then arr_lat[ident]="$f15"; fi
if [ "$f16" != "" ];  then arr_lon[ident]="$f16"; fi
if [ "$f17" != "" ];  then arr_vert[ident]="$f17"; fi
#write default values - important for SQL insert
if [ "${arr_call[ident]}" = "" ]; then arr_call[ident]="unknown"; fi
if [ "${arr_alti[ident]}" = "" ]; then arr_alti[ident]="NULL"; fi
if [ "${arr_velo[ident]}" = "" ]; then arr_velo[ident]="NULL"; fi
if [ "${arr_trck[ident]}" = "" ]; then arr_trck[ident]="NULL"; fi
if [ "${arr_lat[ident]}" = "" ]; then arr_lat[ident]="NULL"; fi
if [ "${arr_lon[ident]}" = "" ]; then arr_lon[ident]="NULL"; fi
if [ "${arr_vert[ident]}" = "" ]; then arr_vert[ident]="NULL"; fi


#----------save ADSB data only if new--------

last_position="_${arr_alti[ident]}_${arr_velo[ident]}_${arr_trck[ident]}_${arr_lat[ident]}_${arr_lon[ident]}_${arr_vert[ident]}_$f7_${arr_call[ident]}"

if [ ident != "" ]; then
if [ -z ${arr_last_position[ident]+"check"} ] || [ ${arr_last_position[ident]} != $last_position ]; then  #if it is same record as before
echo "Position Point received for $f5 ${arr_call[ident]} at alt ${arr_alti[ident]}"

arr_last_position[ident]=$last_position

#---------Create SQL Statement-------

QUERY="INSERT INTO ownradardata "
QUERY="$QUERY (loghexid, logdatetime, latitude, longitude, "
QUERY="$QUERY logsign, altitude, speed, track, vertical) VALUES "
QUERY="$QUERY (\"$f5\",\"$f7 $f8\",${arr_lat[ident]},${arr_lon[ident]},"
QUERY="$QUERY \"${arr_call[ident]}\",${arr_alti[ident]},${arr_velo[ident]},"
QUERY="$QUERY ${arr_trck[ident]},${arr_vert[ident]});"

echo "$QUERY" >> "$ADSB_sql$TimestampMinut.sql"

else #if data is new 
echo "Position Point received for $f5 ${arr_call[ident]} at alt ${arr_alti[ident]} but is not new"
fi #if data is new 
fi #if ident is not empty

#reset the array if it is midnight (fewer planes)
((counter++))   #increase the loop counter
done            #netcat listener loop
Timestamp=$(date +"%Y-%m-%d %H:%M:%S")
echo "Dump2SQL Netcat stopped...Re-Launch with PID $$ at $Timestamp" >> $ADSB_log

done            #outer loop
#-----------------end of the loops----------------
#attention: variables set within the loop stay in the loop

echo "Done for the day..."
echo "Dump2sql done" >> $ADSB_log
echo $(date +"%Y-%m-%d %H:%M%S") >> $ADSB_log