#!/bin/bash
# List files in the current folder
# for each file, count lines and count ingested records
# send results in a new monitoring index
# WARNING: to use this script, jq must be installed on the system

count_lines() {
    local f=$1
    # this is the return value, i.e. non local
    lines_in_files=`wc -l $f | sed 's/^\([0-9]*\).*$/\1/'`
}

parse_file_name() {
    local f=$1
    as_of=`echo $f | cut -c 1-10`
    as_of_time=`echo $f | cut -c 12-19`
}

# Check records already ingested for the current version
check_ingested() {
        lines_in_index=`curl --user $preprod_user $preprod_cloud_url/$index*/_count -d "{ \"query\": {\"bool\": {  \"should\": [ {\"match\": { \"as_of_time\": \"$as_of_time\"}}, {\"match\": { \"as_of\": \"$as_of\"}} ],\"minimum_should_match\": 2 } }}" -H"Content-Type: application/json" | jq -r ".count"`
}

# Post a new record in the monitoring index
post_to_monitoring_index() {
        # we set the date before posting
        date=`date "+%Y-%m-%dT%H:%M:%S"`

        index_post_response=`curl -XPOST -H"Content-Type: application/json" --user $user $cloud_url/$monitoring_index/$record_type -d "{ \"provider\": \"$provider\", \"date\": \"$date\", \"index\": \"$index\",\"file\": \"$file_ref\",\"as_of\": \"$as_of\", \"as_of_time\": \"$as_of_time\", \"num_in_file\": $lines_in_files, \"num_in_index\": $lines_in_index}"`

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
index_post_response=''


# infinit loop : restart every 60 seconds 
while : 
do
        for file_ref in *.csv
        do
                count_lines $file_ref
                lines_in_files=$((lines_in_files - 1)) 
                echo $file_ref $lines_in_files
                parse_file_name $file_ref

                echo $file_ref $as_of

                echo $file_ref $as_of_time

                check_ingested
                echo $file_ref $lines_in_index;

                # get the current date
                date=`date "+%Y-%m-%dT%H:%M:%S"`
                echo $date 
                post_to_monitoring_index
                echo $index_post_response       
        done
echo "sleep 60"
echo "-----------------------------"
sleep 60 
done
