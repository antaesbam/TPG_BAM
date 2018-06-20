#!/bin/bash
# List files in the current folder
# for each file, count lines and count ingested records
# send results in a new monitoring index
# WARNING: to use this script, jq must be installed on the system

count_lines() {
    local f=$1
    # this is the return value, i.e. non local
    l=`wc -l $f | sed 's/^\([0-9]*\).*$/\1/'`
}

parse_file_name() {
    local f=$1
    as_of=`echo $f | cut -c 1-10`
    as_of_time=`echo $f | cut -c 12-19`
}

check_ingested() {
        qr=`curl --user $user $cloud_url/$index*/_count -d "{ \"query\": {\"bool\": {  \"should\": [ {\"match\": { \"as_of_time\": \"$as_of_time\"}}, {\"match\": { \"as_of\": \"$as_of\"}} ],\"minimum_should_match\": 2 } }}" -H"Content-Type: application/json" | jq -r ".count"`
}

post_to_monitoring_index() {
        # we set the date before posting
        date=`date "+%Y-%m-%dT%H:%M:%S"`

        index_post_response=`curl -XPOST -H"Content-Type: application/json" --user $user $cloud_url/$monitoring_index/$record_type -d "{ \"provider\": \"$provider\", \"date\": \"$date\", \"index\": \"$index\",\"file\": \"$f\",\"as_of\": \"$as_of\", \"as_of_time\": \"$as_of_time\", \"num_in_file\": $l, \"num_in_index\": $qr}"`

}

# cloud information
index='tpgbam_dev_mnc'
cloud_url='https://8fb4727ed8b84a938a7f8032d9e73718.eu-central-1.aws.cloud.es.io:9243'
user='elastic:jqoGKYWqopiMXMPBBMf0Bvij'

# count lines in files
l=0

# count records in index
qr=''

as_of=''
as_of_time=''
date=''
monitoring_index='monitoring_ingester_mnc_sms'
record_type='record_count'
provider='mnc'
index_post_response=''


# infinit loop : restart every 5 seconds 
while : 
do
        for f in *.csv
        do
                count_lines $f
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
sleep 5
done