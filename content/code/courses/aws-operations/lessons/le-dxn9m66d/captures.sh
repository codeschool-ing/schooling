#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# traffic.py is read out of the lesson and generates the log lines; its random
# numbers are seeded, so the counts in the prose are the same on every run.
# Timestamps are relative to the moment of the run.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf logs && mkdir logs && cd logs || exit 1
moto_up
student_env
from_lesson "$HERE/../le-a4hvmgna/prices.md" price.py > price.py
from_lesson "$HERE/structured.md" traffic.py > traffic.py

block group
run 'aws logs create-log-group --log-group-name /shop/api'
run "aws logs describe-log-groups --log-group-name-prefix /shop/api --query 'logGroups[0].[logGroupName,retentionInDays,storedBytes]' --output text"
run 'aws logs put-retention-policy --log-group-name /shop/api --retention-in-days 30'
run "aws logs describe-log-groups --log-group-name-prefix /shop/api --query 'logGroups[0].[logGroupName,retentionInDays]' --output text"
block price
run 'python3 price.py AmazonCloudWatch SAE1-DataProcessing-Bytes'
run 'python3 price.py AmazonCloudWatch TimedStorage-ByteHrs'

block put
run 'python3 traffic.py > events.json'
run "jq length events.json && jq -r '.[0].message' events.json"
run 'aws logs create-log-stream --log-group-name /shop/api --log-stream-name api-1'
run "aws logs put-log-events --log-group-name /shop/api --log-stream-name api-1 --log-events file://events.json --query 'rejectedLogEventsInfo'"

block filter
run "aws logs filter-log-events --log-group-name /shop/api --filter-pattern '{ \$.status >= 500 }' --query 'length(events)'"
run "aws logs filter-log-events --log-group-name /shop/api --filter-pattern 'checkout' --query 'length(events)'"

block insights
run "QUERY=\$(aws logs start-query --log-group-name /shop/api --start-time \$(date -d '-1 hour' +%s) --end-time \$(date +%s) --query-string 'filter status >= 500 | stats count(*) as errors by path' --query queryId --output text)"
QUERY=$(aws logs start-query --log-group-name /shop/api --start-time $(date -d '-1 hour' +%s) --end-time $(date +%s) --query-string 'filter status >= 500 | stats count(*) as errors by path' --query queryId --output text)
sleep 1
run "aws logs get-query-results --query-id \$QUERY --query '[status, length(results), results[0][0]]'"

block export
run "aws logs filter-log-events --log-group-name /shop/api --query 'events[].message' --output json | jq -r '.[]' > api.jsonl"
run 'wc -l api.jsonl'
block jq-errors
run "jq -r 'select(.status >= 500) | .path' api.jsonl | sort | uniq -c | sort -rn"
block jq-slow
run "jq -r 'select(.path == \"/checkout\") | .ms' api.jsonl | sort -n | awk '{ v[NR] = \$1 } END { print \"requests\", NR, \"p50\", v[int(NR * 0.5)], \"p99\", v[int(NR * 0.99)] }'"
block jq-customer
run "jq -r 'select(.status >= 500) | .customer' api.jsonl | sort | uniq -c | sort -rn | head -3"

block metric-filter
run "aws logs put-metric-filter --log-group-name /shop/api --filter-name errors-5xx --filter-pattern '{ \$.status >= 500 }' --metric-transformations metricName=Errors5xx,metricNamespace=Shop,metricValue=1,defaultValue=0"
run "aws logs describe-metric-filters --log-group-name /shop/api --query 'metricFilters[0].[filterName,filterPattern,metricTransformations[0].metricName]' --output text"
run "jq -n --arg t \"\$(date +%s000)\" '[{timestamp: (\$t | tonumber), message: ({status: 503, path: \"/checkout\"} | tojson)}]' > one.json"
run "aws logs put-log-events --log-group-name /shop/api --log-stream-name api-1 --log-events file://one.json --query rejectedLogEventsInfo"
run "aws cloudwatch list-metrics --namespace Shop --query 'Metrics'"
