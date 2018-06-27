#!/bin/bash
# List files in the current folder
# for each file, count lines and count ingested records
# send results in a new monitoring index
# WARNING: to use this script, jq must be installed on the system

define_time_limit() {
        local ct=`date +%s`
        echo $ct
        local num_days_limit_seconds=$((num_days_limit * 3600 * 24))
        echo $num_days_limit_seconds
        time_limit=$((ct - num_days_limit_seconds))
}


check_files_to_archive() {
        local f=$1
        echo 'file:' $f
        local f_time=`date -r $f +%s`
        if [$time_limit -ge $f_time]
        then
                echo $time_limit 'greater' $f_time
        fi

}

# define folder to monitor
target_folder='/home/mnc/publish'
# define tim limit
time_limit=0
# number of days for time limit
num_days_limit=1

# initialize time_limit
define_time_limit
echo $time_limit

# infinit loop : restart every 5 seconds 
while : 
do
        for f in $target_folder/*.csv
        do
                check_files_to_archive $f

        done
echo "sleep 60"
echo "-----------------------------"
sleep 60
done