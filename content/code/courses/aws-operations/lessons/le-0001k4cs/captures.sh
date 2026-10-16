#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# moto keeps budgets and alarms and has no spend: the budget's actual spend
# is 0 and nothing is ever notified. days.py writes a made-up 45 days of cost;
# days.py, spike.py, budget.json and notifications.json are read out of the
# lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf bill && mkdir bill && cd bill || exit 1
moto_up
student_env
from_lesson "$HERE/budgets.md" budget.json > budget.json
from_lesson "$HERE/budgets.md" notifications.json > notifications.json
from_lesson "$HERE/spikes.md" days.py > days.py
from_lesson "$HERE/spikes.md" spike.py > spike.py

block budget
run 'aws sns create-topic --name billing --region us-east-1 --query TopicArn --output text'
run 'aws budgets create-budget --account-id 123456789012 --budget file://budget.json --notifications-with-subscribers file://notifications.json'
run "aws budgets describe-budgets --account-id 123456789012 --query 'Budgets[].[BudgetName,BudgetLimit.Amount,TimeUnit,CalculatedSpend.ActualSpend.Amount]' --output text"
run "aws budgets describe-notifications-for-budget --account-id 123456789012 --budget-name shop-monthly --query 'Notifications[].[NotificationType,ComparisonOperator,Threshold]' --output text"

block alarm
run 'aws cloudwatch put-metric-alarm --region us-east-1 --alarm-name bill-over-1600 --namespace AWS/Billing --metric-name EstimatedCharges --dimensions Name=Currency,Value=USD --statistic Maximum --period 21600 --evaluation-periods 1 --threshold 1600 --comparison-operator GreaterThanThreshold --alarm-actions arn:aws:sns:us-east-1:123456789012:billing'
run "aws cloudwatch describe-alarms --region us-east-1 --query 'MetricAlarms[].[AlarmName,Namespace,MetricName,StateValue]' --output text"
run 'aws cloudwatch list-metrics --region us-east-1 --namespace AWS/Billing'

block spikes
run 'python3 days.py'
run 'python3 spike.py'

block anomaly
run "aws ce create-anomaly-monitor --anomaly-monitor '{\"MonitorName\":\"services\",\"MonitorType\":\"DIMENSIONAL\",\"MonitorDimension\":\"SERVICE\"}' 2>&1 | grep -m1 ERROR"
