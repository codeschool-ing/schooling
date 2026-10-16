#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of aws-data (MWAA, and Step
# Functions with EventBridge Scheduler), as a script that produces them. Every
# transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE LAB IS LESSON 1'S, and this script starts where a student is after "Every
# time you open a terminal", with moto empty. moto 5.2.3 has no MWAA, and the
# lesson's second section is about exactly that; Step Functions and Scheduler
# are stored and never executed, which the lesson says beside each transcript.
#
# The files the student saves are read out of the lesson: nightly_orders.py from
# the example in airflow-parts.md, nightly.json and target.json from the fences
# introduced by their names in step-functions.md and scheduling.md.
#
# STAGED, in block mwaa-resolved: the MWAA command line asks for api.localhost.
# Ubuntu's own resolver answers names under .localhost with 127.0.0.1; the
# recording machine's has no such rule, so the name does not resolve there
# (block mwaa-noconnect shows that). For mwaa-resolved one line,
# "127.0.0.1 api.localhost", is added to a copy of /etc/hosts bind-mounted inside
# this capture's own mount namespace, so the transcript shows what a student
# whose resolver answers sees. Nothing outside the capture is changed.
#
# STAGED: the price cache is full when this starts, because lab.sh tools ran the
# whole sheet once, which is the first step lesson 1's price sheet asks for.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
L="$LESSONS/le-k68896md"

example "$L/airflow-parts.md" nightly_orders.py nightly_orders.py || exit 1
block mwaa-dagfolder
run 'aws s3 mb s3://quitanda-airflow-prod'
run 'aws s3api put-bucket-versioning --bucket quitanda-airflow-prod --versioning-configuration Status=Enabled'
run 'aws s3 cp nightly_orders.py s3://quitanda-airflow-prod/dags/nightly_orders.py'
run 'aws s3api list-object-versions --bucket quitanda-airflow-prod --query "Versions[].[Key,IsLatest]" --output text'

block mwaa-noconnect
run 'aws mwaa list-environments'
run 'AWS_ENDPOINT_URL=http://127.0.0.1:4567 aws mwaa list-environments'
run "aws mwaa list-environments --debug 2>&1 | grep -o \"'host_prefix': '[^']*'\""
run 'getent hosts api.localhost; echo "exit $?"'

block mwaa-resolved
HOSTS=$(mktemp); cat /etc/hosts > "$HOSTS"; echo '127.0.0.1 api.localhost' >> "$HOSTS"
mount --bind "$HOSTS" /etc/hosts || exit 1
run 'getent hosts api.localhost'
run 'aws mwaa list-environments'
run "curl -s -o /dev/null -w '%{http_code}\\n' http://localhost:4567/environments"
umount /etc/hosts

block price-mwaa
run 'python3 prices.py mwaa'

file_fence "$L/step-functions.md" nightly.json > nightly.json || exit 1
block sfn-create
run 'aws stepfunctions create-state-machine --name quitanda-nightly --definition file://nightly.json --role-arn arn:aws:iam::123456789012:role/quitanda-sfn'
SM=arn:aws:states:sa-east-1:123456789012:stateMachine:quitanda-nightly
run "aws stepfunctions start-execution --state-machine-arn $SM --input '{\"scheduled\": \"2026-10-16T03:00:00-03:00\"}'"
EX=$(aws stepfunctions list-executions --state-machine-arn "$SM" --query 'executions[0].executionArn' --output text)
run "aws stepfunctions describe-execution --execution-arn $EX --query '[status,input,output]'"
run "aws stepfunctions get-execution-history --execution-arn $EX --query 'events[].type'"
run 'aws glue get-job-runs --job-name load-orders'

file_fence "$L/scheduling.md" target.json > target.json || exit 1
block sched-create
run "aws scheduler create-schedule --name quitanda-nightly --schedule-expression 'cron(0 3 * * ? *)' --schedule-expression-timezone America/Sao_Paulo --flexible-time-window Mode=OFF --target file://target.json"
run 'aws scheduler get-schedule --name quitanda-nightly'

block sched-five
run "aws scheduler create-schedule --name quitanda-five-fields --schedule-expression 'cron(0 3 * * *)' --flexible-time-window Mode=OFF --target file://target.json"
run "aws scheduler list-schedules --query 'Schedules[].[Name,State]' --output text"
