#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# The data points are the ones the lesson's commands publish, at the time of
# the run; percentile.py and dashboard.json are read out of the lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf metrics && mkdir metrics && cd metrics || exit 1
moto_up
student_env
from_lesson "$HERE/../le-a4hvmgna/prices.md" price.py > price.py

block publish
run 'aws cloudwatch put-metric-data --namespace Shop --metric-name Orders --dimensions Service=api,Stage=prod --unit Count --value 12'
run 'aws cloudwatch put-metric-data --namespace Shop --metric-name Orders --dimensions Service=api,Stage=staging --unit Count --value 3'
run "aws cloudwatch list-metrics --namespace Shop --query 'Metrics[].Dimensions[].[Name,Value]' --output text"
block identity
run 'START=$(date -u -d "-10 min" +%FT%TZ); END=$(date -u -d "+1 min" +%FT%TZ)'
START=$(date -u -d "-10 min" +%FT%TZ); END=$(date -u -d "+1 min" +%FT%TZ)
run "aws cloudwatch get-metric-statistics --namespace Shop --metric-name Orders --dimensions Name=Service,Value=api Name=Stage,Value=prod --start-time \$START --end-time \$END --period 600 --statistics Sum --query 'Datapoints[].Sum'"
run "aws cloudwatch get-metric-statistics --namespace Shop --metric-name Orders --dimensions Name=Service,Value=api --start-time \$START --end-time \$END --period 600 --statistics Sum --query 'Datapoints[].Sum'"
run "aws cloudwatch get-metric-statistics --namespace Shop --metric-name Orders --start-time \$START --end-time \$END --period 600 --statistics Sum --query 'Datapoints[].Sum'"

block latency
run "aws cloudwatch put-metric-data --namespace Shop --metric-data 'MetricName=Latency,Dimensions=[{Name=Service,Value=api}],Unit=Milliseconds,Values=[40,42,45,900],Counts=[50,30,15,5]'"
run "aws cloudwatch get-metric-statistics --namespace Shop --metric-name Latency --dimensions Name=Service,Value=api --start-time \$START --end-time \$END --period 600 --statistics SampleCount Average Maximum --query 'Datapoints[0]'"
block p99
run "aws cloudwatch get-metric-statistics --namespace Shop --metric-name Latency --dimensions Name=Service,Value=api --start-time \$START --end-time \$END --period 600 --extended-statistics p99 --query 'Datapoints'"
from_lesson "$HERE/statistics.md" percentile.py > percentile.py
block percentile
run 'python3 percentile.py'

block price
run 'python3 price.py AmazonCloudWatch MetricMonitorUsage'
run 'python3 price.py AmazonCloudWatch CW:Requests'

from_lesson "$HERE/dashboards.md" dashboard.json > dashboard.json
block dashboard
run 'aws cloudwatch put-dashboard --dashboard-name shop-api --dashboard-body file://dashboard.json'
run "aws cloudwatch list-dashboards --query 'DashboardEntries[].[DashboardName,Size]' --output text"
run "aws cloudwatch get-dashboard --dashboard-name shop-api --query DashboardBody --output text | jq '.widgets | length'"
