#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S: the table is the first ```sh fence of
# units.md, cost.py is the schooling-example of break-even.md, policy.json and
# flood.py are the fences those files introduce in autoscaling.md and
# throttling.md. cost.py imports the price sheet, prices.py, which lab.sh put
# in ~/aws with its cache full. moto is empty when this starts.
#
# STAGED: nothing beyond what lab.sh stages for every lesson. The timing that
# flood.py prints is this machine's against moto, and changes between runs.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
L="$HERE"
KEY="'{\"sku\": {\"S\": \"coffee-500g\"}}'"

# ---- units -----------------------------------------------------------------------
bash -e <(fence "$L/units.md" 1) || exit 1
block units-moto
run "python3 -c \"import json; print(json.dumps({'sku': {'S': 'coffee-500g'}, 'description': {'S': 'x' * 9000}}))\" > coffee.json"
run 'wc -c coffee.json'
run "aws dynamodb put-item --table-name products --item file://coffee.json --return-consumed-capacity TOTAL --query ConsumedCapacity.CapacityUnits"
run "aws dynamodb get-item --table-name products --key $KEY --return-consumed-capacity TOTAL --query ConsumedCapacity.CapacityUnits"
run "aws dynamodb get-item --table-name products --key $KEY --consistent-read --return-consumed-capacity TOTAL --query ConsumedCapacity.CapacityUnits"
run "aws dynamodb transact-get-items --transact-items '[{\"Get\": {\"TableName\": \"products\", \"Key\": {\"sku\": {\"S\": \"coffee-500g\"}}}}]' --return-consumed-capacity TOTAL --query 'ConsumedCapacity[0].CapacityUnits'"
run "aws dynamodb transact-write-items --transact-items '[{\"Put\": {\"TableName\": \"products\", \"Item\": {\"sku\": {\"S\": \"tea-250g\"}}}}]' --return-consumed-capacity TOTAL --query ConsumedCapacity"

# ---- two-modes -------------------------------------------------------------------
block modes-price
run 'python3 prices.py dynamodb'
block modes-switch
run "aws dynamodb describe-table --table-name products --query 'Table.[BillingModeSummary.BillingMode,WarmThroughput]'"
run "aws dynamodb update-table --table-name products --billing-mode PROVISIONED --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 --query 'TableDescription.[BillingModeSummary.BillingMode,ProvisionedThroughput]'"
run "aws dynamodb update-table --table-name products --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=3 --query 'TableDescription.ProvisionedThroughput'"
run "aws dynamodb update-table --table-name products --billing-mode PAY_PER_REQUEST --query 'TableDescription.BillingModeSummary.BillingMode'"
run "aws dynamodb update-table --table-name products --billing-mode PROVISIONED --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 --query 'TableDescription.BillingModeSummary.BillingMode'"

# ---- break-even ------------------------------------------------------------------
example "$L/break-even.md" cost.py cost.py
block cost-runs
run 'python3 cost.py steady'
run 'python3 cost.py spiky'

# ---- autoscaling -----------------------------------------------------------------
file_fence "$L/autoscaling.md" policy.json > policy.json
block scale-setup
run 'aws application-autoscaling register-scalable-target --service-namespace dynamodb --resource-id table/products --scalable-dimension dynamodb:table:WriteCapacityUnits --min-capacity 5 --max-capacity 500'
run 'aws application-autoscaling put-scaling-policy --service-namespace dynamodb --resource-id table/products --scalable-dimension dynamodb:table:WriteCapacityUnits --policy-name products-writes --policy-type TargetTrackingScaling --target-tracking-scaling-policy-configuration file://policy.json --query "Alarms[].AlarmName"'
block scale-alarms
run "aws cloudwatch describe-alarms --query 'MetricAlarms[].[MetricName,ComparisonOperator,Threshold,Period,EvaluationPeriods]' --output text"
run "aws application-autoscaling describe-scaling-activities --service-namespace dynamodb --resource-id table/products 2>&1 | head -2"

# ---- throttling ------------------------------------------------------------------
file_fence "$L/throttling.md" flood.py > flood.py
block throttle-flood
run 'python3 flood.py'
run "aws dynamodb describe-table --table-name products --query 'Table.[ItemCount,ProvisionedThroughput.WriteCapacityUnits]' --output text"
