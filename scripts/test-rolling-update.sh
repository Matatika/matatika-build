#!/bin/bash
TEST_URL=$1
if [ -z "$TEST_URL" ]; then
	TEST_URL=https://app-staging.matatika.com
	echo "INFO: no test url argument supplied using $TEST_URL";
fi


while true; do
    curl -s -o /dev/null -w "%{http_code} %{size_download}" $TEST_URL
    echo 
    sleep 1s
done
