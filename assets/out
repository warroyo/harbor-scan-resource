#!/bin/bash

set -e -u

exec 3>&1 # make stdout available as fd 3 for the result
exec 1>&2 # redirect all output to stderr for logging

source $(dirname $0)/common.sh

source=$1

if [ -z "$source" ]; then
  echo "usage: $0 <path/to/source>"
  exit 1
fi

payload=$(mktemp /tmp/harbor-scan-resource-request.XXXXXX)

cat > $payload <&0

cd $source

username=$(jq -r '.source.username // ""' < $payload)
password=$(jq -r '.source.password // ""' < $payload)
repository="$(jq -r '.params.repository // ""' < $payload)"
tag="$(jq -r '.params.tag // "latest"' < $payload)"
harbor_host=$(jq -r '.source.harbor_host // ""' < $payload)
harbor_scan_thresholds=$(jq -r '.params.harbor_scan_thresholds // ""' < $payload)

export harbor_image=$(echo $repository | cut -f2- -d '/')
export harbor_respoitory_encoded=$(urlencode $harbor_image)
export scan_check_tries=10
export scan_check_interval=5

harbor_curl_scan() {
    	response=$(curl -sk --write-out "%{http_code}\n" --output /dev/null -H "Content-Type: application/json" -X POST --user $username:$password "https://$harbor_host/api/repositories/$harbor_respoitory_encoded/tags/$tag/scan" )
    	if [ $response != "200" ]; then
    		echo "Failed to initiate Harbor Scan on https://$harbor_host/api/repositories/$harbor_respoitory_encoded/tags/$tag !!!"
    		exit 1
    	else
    		echo "Scan Initiated on https://$harbor_host/api/repositories/$harbor_respoitory_encoded/tags/$tag ..."
    	fi
    }

harbor_curl_scan_check() {
    response=$(curl -sk -H "Content-Type: application/json" -X GET --user $username:$password "https://$harbor_host/api/repositories/$harbor_respoitory_encoded/tags/$tag" | jq .scan_overview.scan_status | tr -d "\"")
    echo $response
}

harbor_curl_scan_summary() {
    response=$(curl -sk -H "Content-Type: application/json" -X GET --user $username:$password "https://$harbor_host/api/repositories/$harbor_respoitory_encoded/tags/$tag" | jq .scan_overview.components)
        echo $response
}

harbor_curl_scan_details() {
        response=$(curl -sk -H "Content-Type: application/json" -X GET --user $username:$password "https://$harbor_host/api/repositories/$harbor_respoitory_encoded/tags/$tag/vulnerability/details" | jq .)
        echo $response
}

echo "Triggering Image scan..."
  	harbor_curl_scan


# Check if Scan is complete or if it hasnt been triggered.

for i in $(seq 1 $scan_check_tries);
do
    scan_state=$(harbor_curl_scan_check)
    echo "Checking if Clair Scan is finished, attempt $i of $scan_check_tries ... RESULT: $scan_state"
    if [ $scan_state = "finished" ]; then
        echo "Clair Scan Complete"
        break
    else
        sleep $scan_check_interval
    fi
done

# Checkpipeline thresholds & print Summary Report
echo "Harbor Summary Report of CVE's found:"
harbor_curl_scan_summary=$(harbor_curl_scan_summary)

echo $harbor_curl_scan_summary | jq .

# Check Tresholds Json & Trigger if summary CVEs exceed
threshold_trigger=false

for row in $(echo "${harbor_scan_thresholds}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | base64 -d | jq -r ${1}
    }

    cve_sev=$(_jq '.severity')
    cve_threshold=$(_jq '.count')

    get_count_cmd="echo '$harbor_curl_scan_summary' | jq ' .summary[] | select(.severity == $cve_sev) | .count'"
    count=$(eval $get_count_cmd)
    if [ ! -z $count ] && [ $count -gt $cve_threshold ]; then
        echo "Image exceed threshold of $cve_threshold for CVE-Severity:$cve_sev with a count of $count"
        threshold_trigger=true
    fi
done

if [ $threshold_trigger = true ]; then
    echo "One or more Clair Scan Thresholds have been exceeded !!!"
    echo "Collecting CVE Scan Details from Harbor ..."
    echo "==========================================================================="
    echo "DETAILED CVE ANALYSIS:"
    echo "==========================================================================="

    harbor_curl_scan_details | jq .
    exit 1
fi

jq -n "{
  version: {}
}" >&3