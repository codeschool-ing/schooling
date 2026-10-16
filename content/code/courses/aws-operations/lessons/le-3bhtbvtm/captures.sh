#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# STAGED: the shop's five alarms are created beforehand, all paging, as the
# lesson describes them before the tuning; nothing in moto evaluates them.
# rotation.py, month.py and fatigue.py are read out of the lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf oncall && mkdir oncall && cd oncall || exit 1
from_lesson "$HERE/rotation.md" rotation.py > rotation.py
from_lesson "$HERE/fatigue.md" month.py > month.py
from_lesson "$HERE/fatigue.md" fatigue.py > fatigue.py
from_lesson "$HERE/tuning.md" to-ticket.jq > to-ticket.jq

block rotation
run 'python3 rotation.py'
block month
run 'python3 month.py'
run 'head -4 pages.csv'
block fatigue
run 'python3 fatigue.py'
block symptoms
run 'python3 fatigue.py api-errors api-latency'

moto_up
student_env
PAGE=arn:aws:sns:sa-east-1:123456789012:shop-page
quiet 'aws sns create-topic --name shop-page'
alarm() { # name metric statistic threshold periods datapoints
  quiet "aws cloudwatch put-metric-alarm --alarm-name $1 --namespace Shop --metric-name $2 --dimensions Name=Service,Value=api --statistic $3 --period 300 --threshold $4 --evaluation-periods $5 --datapoints-to-alarm $6 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching --alarm-actions $PAGE --ok-actions $PAGE"
}
alarm api-errors Errors5xx Sum 10 5 3
alarm api-latency LatencyP99 Maximum 800 5 3
alarm db-cpu DbCpu Average 80 1 1
alarm queue-depth QueueDepth Maximum 500 1 1
alarm disk-80 DiskUsedPercent Maximum 80 1 1

block tuning
run "aws cloudwatch describe-alarms --query 'MetricAlarms[].[AlarmName,AlarmActions[0]]' --output text"
run 'TICKET=$(aws sns create-topic --name shop-ticket --query TopicArn --output text); echo $TICKET'
block tuning-db
run 'jq --arg t "$TICKET" -f to-ticket.jq <(aws cloudwatch describe-alarms --alarm-names db-cpu --query MetricAlarms[0]) > db-cpu.json'
run 'aws cloudwatch put-metric-alarm --cli-input-json file://db-cpu.json'
run 'jq --arg t "$TICKET" -f to-ticket.jq <(aws cloudwatch describe-alarms --alarm-names queue-depth --query MetricAlarms[0]) > queue-depth.json'
run 'aws cloudwatch put-metric-alarm --cli-input-json file://queue-depth.json'
block tuning-disk
run 'jq --arg t "$TICKET" -f to-ticket.jq <(aws cloudwatch describe-alarms --alarm-names disk-80 --query MetricAlarms[0]) | jq ".EvaluationPeriods = 12 | .DatapointsToAlarm = 12" > disk-80.json'
run 'aws cloudwatch put-metric-alarm --cli-input-json file://disk-80.json'
block tuning-after
run "aws cloudwatch describe-alarms --query 'MetricAlarms[].[AlarmName,AlarmActions[0],EvaluationPeriods]' --output text"
