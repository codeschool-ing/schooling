#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# The error counts are published by the loop the lesson shows (read out of it),
# at minutes relative to the run; alarm.py is read out of the lesson too. It is
# a model of CloudWatch's documented evaluation, and the lesson says so.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf alarms && mkdir alarms && cd alarms || exit 1
moto_up
student_env
from_lesson "$HERE/../le-a4hvmgna/prices.md" price.py > price.py
from_lesson "$HERE/evaluate.md" alarm.py > alarm.py

block create
run "aws sns create-topic --name shop-oncall --query TopicArn --output text"
run "aws cloudwatch put-metric-alarm --alarm-name api-errors --namespace Shop --metric-name Errors5xx --dimensions Name=Service,Value=api --statistic Sum --period 60 --evaluation-periods 5 --datapoints-to-alarm 3 --threshold 10 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching --alarm-actions arn:aws:sns:sa-east-1:123456789012:shop-oncall --ok-actions arn:aws:sns:sa-east-1:123456789012:shop-oncall"
run "aws cloudwatch describe-alarms --alarm-names api-errors --query 'MetricAlarms[0].[StateValue,StateReason,DatapointsToAlarm,EvaluationPeriods,TreatMissingData]' --output text"

block publish
# shellcheck disable=SC1090
. <(python3 - "$HERE/evaluate.md" <<'PY'
import re, sys
print(re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)[0])
PY
)
run "aws cloudwatch describe-alarms --alarm-names api-errors --query 'MetricAlarms[0].[StateValue,StateReason]' --output text"

block evaluate
run 'python3 alarm.py notBreaching'
block evaluate-missing
run 'python3 alarm.py breaching | tail -4'
run 'python3 alarm.py ignore | tail -4'

put notification.json <<'EOF2'
{
  "AlarmName": "api-errors",
  "NewStateValue": "ALARM",
  "NewStateReason": "Threshold Crossed: 3 out of the last 5 datapoints were greater than the threshold (10.0).",
  "OldStateValue": "OK",
  "Region": "South America (Sao Paulo)",
  "Trigger": {
    "MetricName": "Errors5xx",
    "Namespace": "Shop",
    "Statistic": "SUM",
    "Period": 60,
    "EvaluationPeriods": 5,
    "DatapointsToAlarm": 3,
    "ComparisonOperator": "GreaterThanThreshold",
    "Threshold": 10.0,
    "TreatMissingData": "notBreaching"
  }
}
EOF2
block sns
run "QUEUE=\$(aws sqs create-queue --queue-name oncall-inbox --query QueueUrl --output text)"
QUEUE=$(aws sqs create-queue --queue-name oncall-inbox --query QueueUrl --output text)
run "aws sns subscribe --topic-arn arn:aws:sns:sa-east-1:123456789012:shop-oncall --protocol sqs --notification-endpoint arn:aws:sqs:sa-east-1:123456789012:oncall-inbox --query SubscriptionArn --output text"
run "aws cloudwatch set-alarm-state --alarm-name api-errors --state-value ALARM --state-reason 'set by hand to test the route'"
run "aws sqs receive-message --queue-url \$QUEUE --wait-time-seconds 2 --query 'length(Messages || \`[]\`)'"
run "aws sns publish --topic-arn arn:aws:sns:sa-east-1:123456789012:shop-oncall --subject 'ALARM: api-errors' --message file://notification.json --query MessageId --output text"
run "aws sqs receive-message --queue-url \$QUEUE --wait-time-seconds 2 --query 'Messages[0].Body' --output text | jq -r .Message | jq '{AlarmName, NewStateValue, NewStateReason}'"

block composite
run "aws cloudwatch put-composite-alarm --alarm-name api-down --alarm-rule 'ALARM(\"api-errors\") AND ALARM(\"api-latency\")' 2>&1 | grep -m1 ERROR"
block price
run 'python3 price.py AmazonCloudWatch AlarmMonitorUsage'
