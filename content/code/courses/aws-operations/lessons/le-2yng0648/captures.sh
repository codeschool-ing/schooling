#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# STAGED: the incident is compressed into about half a minute. A deployment is
# recorded, error lines are written to the API's log group, and the alarm is set
# to ALARM by hand (moto evaluates no alarm), with pauses between, so the three
# sources carry timestamps in the order an incident produces them.
# timeline.py is read out of the lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf incident && mkdir incident && cd incident || exit 1
moto_up
student_env
from_lesson "$HERE/timeline.md" timeline.py > timeline.py

quiet 'aws deploy create-application --application-name shop-api --compute-platform ECS'
quiet 'aws deploy create-deployment-group --application-name shop-api --deployment-group-name prod --service-role-arn arn:aws:iam::123456789012:role/shop-deploy --deployment-config-name CodeDeployDefault.ECSCanary10Percent5Minutes'
quiet 'aws logs create-log-group --log-group-name /shop/api'
quiet 'aws logs create-log-stream --log-group-name /shop/api --log-stream-name api-1'
quiet 'aws cloudwatch put-metric-alarm --alarm-name api-errors --namespace Shop --metric-name Errors5xx --dimensions Name=Service,Value=api --statistic Sum --period 60 --evaluation-periods 5 --datapoints-to-alarm 3 --threshold 10 --comparison-operator GreaterThanThreshold'
sleep 2
quiet 'aws deploy create-deployment --application-name shop-api --deployment-group-name prod --revision "{\"revisionType\":\"AppSpecContent\",\"appSpecContent\":{\"content\":\"version: 0.0\"}}"'
sleep 8
for path in /checkout /checkout /cart; do
  jq -n --arg t "$(date +%s%3N)" --arg p "$path" '[{timestamp: ($t | tonumber), message: ({status: 503, path: $p} | tojson)}]' > one.json
  quiet 'aws logs put-log-events --log-group-name /shop/api --log-stream-name api-1 --log-events file://one.json'
  sleep 3
done
sleep 6
quiet "aws cloudwatch set-alarm-state --alarm-name api-errors --state-value ALARM --state-reason '3 of the last 5 minutes above 10'"

block timeline
run 'python3 timeline.py'
