#!/bin/bash
# List files in the current folder
# for each file, count lines and count ingested records
# compair results between index and file to check if file was fully ingested
# check also the file last modification date: 
# if last modification is more than 24 hour --> the file is archived

# Utilities library **********************************

# define the limit of time to check files
define_time_limit() {
        local ct=`date +%s`
        local num_days_limit_seconds=$((num_days_limit * 3600 * 24))
        time_limit=$((ct - num_days_limit_seconds))
}

# file management library ***************************
# count lines in current file 
count_lines() {
    local f=$1
    # this is the return value, i.e. non local
    lines_in_files=`wc -l $f | sed 's/^\([0-9]*\).*$/\1/'`
}

# gather from file : as_of & as_of_time 
parse_file_name() {
    local f=`basename "${1}"`
    echo 'BASENAME:' $f
    as_of=`echo $f | cut -c 1-10`
    as_of_time=`echo $f | cut -c 12-19`
}

# Check time limit for the current input file 
check_files_to_archive() {
        local f=$1
        local f_time=`date -r $f +%s`
        if ((time_limit > f_time));
        then
                echo $time_limit 'greater' $f_time
                file_to_archive=true
        fi

}

# archive input file
transfert_to_archive_folder() {
        local f=$archive_folder/`basename "${1}"`
        echo 'CHECK FILE EXISTS:' $f
        if [ ! -f $f ]
        then
                echo 'READY TO ARCHIVE FILE : ' $f
                `cp $1 $archive_folder/`
        fi
}

# Index management library *************************

# Check records already ingested for the current version
check_ingested() {
        lines_in_index=`curl --user $preprod_user $preprod_cloud_url/$index*/_count -d "{ \"query\": {\"bool\": {  \"should\": [ {\"match\": { \"as_of_time\": \"$as_of_time\"}}, {\"match\": { \"as_of\": \"$as_of\"}} ],\"minimum_should_match\": 2 } }}" -H"Content-Type: application/json" | jq -r ".count"`
}


# cloud information
# publishing index
index='tpgbam_dev_mnc'
preprod_cloud_url='https://8fb4727ed8b84a938a7f8032d9e73718.eu-central-1.aws.cloud.es.io:9243'
preprod_user='elastic:jqoGKYWqopiMXMPBBMf0Bvij'

# Dev platform cloud information: targeted as the monitoring platform
cloud_url='https://416d580d881f24fb8cc3e9be04c9ce89.us-west-2.aws.found.io:9243'
user='elastic:5PPjNy8uvv61ogJfMMlhVQZO'


# count lines in files
lines_in_files=0

# count records in index
lines_in_index=''

as_of=''
as_of_time=''
date=''
monitoring_index='monitoring_ingester_mnc_sms'
record_type='record_count'
provider='mnc'

# define folder to monitor
target_folder='/home/mnc/publish'
# folder for archiving
archive_folder='/home/mnc/archive'
# define tim limit
time_limit=0
# number of days for time limit
num_days_limit=1
# is file ready for archiving
file_to_archive=false

# initialize time_limit for the current execution
define_time_limit
echo $time_limit

# infinit loop : restart every 5 seconds 
while : 
do
        for f in $target_folder/*.csv
        do
                file_ref=$f
                echo 'file:' $file_ref
                # Check if file is holder than 24 hour
                check_files_to_archive $file_ref

                # if file is ready for archiving then we check integration in index
                if $file_to_archive
                then
                        echo 'file is ready for archiving:' $file_ref
                        # count line sin file
                        count_lines $file_ref
                        lines_in_files=$((lines_in_files - 1))
                        echo 'LINES IN FILE:' $file_ref $lines_in_files
                        parse_file_name $file_ref

                        echo 'FILE AS_OF:' $file_ref $as_of

                        echo 'FILE AS_OF_TIME:' $file_ref $as_of_time

                        #count lines in index for file as_of - as_of_time 
                        check_ingested
                        echo 'LINE IN INDEX:' $file_ref $lines_in_index;
                        if ((lines_in_index>=lines_in_files));
                        then
                                # send file to archive folder
                                echo 'ARCHIVE FILE:' $file_ref
                                transfert_to_archive_folder $file_ref
                        fi
                        # reset the flag for archiving
                        file_to_archive=false
                fi
        done
echo "sleep 5"
echo "-----------------------------"
sleep 60
done

