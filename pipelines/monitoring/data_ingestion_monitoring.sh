#!/bin/bash
# List files in the current folder
# for each file, count lines and count ingested records
# send results in a new monitoring index
# WARNING: to use this script, jq must be installed on the system


check_files_to_archive() {
	local f=$1
	
}

# define folder to monitor
target_folder




# infinit loop : restart every 5 seconds 
while : 
do
        for f in $target_folder/*.csv
        do
                check_files_to_archive $f
                l=$((l - 1)) 
                echo $f $l
                parse_file_name $f

                echo $f $as_of

                echo $f $as_of_time

                check_ingested
                echo $f $qr;

                # get the current date
                date=`date "+%Y-%m-%dT%H:%M:%S"`
                echo $date 
                post_to_monitoring_index
                echo $index_post_response       
        done
echo "sleep 5"
echo "-----------------------------"
sleep 60 
done
