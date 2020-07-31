#!/bin/bash

# Version 0.1

# This utility looks for misconfigured server log entries for sendmail and executes CSF to ban the IP for TTL duration.
# It is was developed to meet my own need and I'm sharing it here
# It was developed on a Centos 6 server running Sendmail, ConfigServer Firewall
# When used with other scripts I wrote, the amount of garbage email goes down considerably

# CSF binary location:
CSF=/usr/sbin/csf

# location of your mail log file:
LOGFILE="/var/log/maillog"

# REQUIRED: Crate file that script uses to know when to short circuit and exit.
# This trigger is also used by other scripts in my sendmail project
# to create the spam_killall file, use this command:
# echo "0" > /root/scripts/spam_killall.txt

# spam_killall file contains 1 or 0
#	1 = script should exit
#	2 = script should continue
#

KA=`cat /root/scripts/spam_kllall.txt`

if [ $KA -eq 1 ]; then
        echo "Kill all set - exiting"
        exit 1
fi

# EXCLUDE IP From Logfile
SKIPIPLIST="192.168.202.17 \| 174.53.76.211"

# How long to ban the IP for
TTL="24hr"

# You should not need to change anything below this point

LASTHOUR=`date -d '1 days ago' "+%b %e %H"`
THISHOUR=`date "+%b %e %H"`

# Search up to the last 2 hours of the log, look for target line, remove protected IP, make a sorted unique list of IP and number of occurances
RESULT=`grep "$LASTHOUR\|$THISHOUR" $LOGFILE|grep "Email rejected due to sending server misconfiguration"|grep -v "$SKIPIPLIST"|awk -F"[" '{print $3}'|awk -F "]" '{print $1}'|sort|uniq -c|awk '{if ($1 > 1) print $1","$2}'` 

# Loop through the results and separate ip and occuance count into separate variables, then build and execute CSF command
for ITEM in $RESULT; do 
        SENDERIP=`echo $ITEM|awk -F"," '{print $2}'`
        FCount=`echo $ITEM|awk -F"," '{print $1}'`

        echo "csf -td $SENDERIP" "$TTL" "Excssive Email From Misconfigured Server ($FCount)"
        $CSF -td "$SENDERIP" "$TTL" "Excssive Email From Misconfigured Server ($FCount)"
done
