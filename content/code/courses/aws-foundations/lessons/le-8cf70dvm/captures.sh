#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty, seeded moto. The files the student writes are read out of the lesson:
# budget.json and notifications.json from the ```sh fence of "budgets",
# tag-policy.json from the ```sh fence of "tags". price.py is lesson 1's.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - a 500 from moto is printed whole by the AWS command line, five lines of
#     HTML; the commands that meet one pipe their output through `grep ERROR`,
#     and the prose shows that pipe, so the line quoted is the line that names it;
#   - the instance ids quoted in later commands are the ones the seeded moto
#     gives; a student's moto gives others, and the prose says so.
#
# TWO COMMANDS REACH AWS ITSELF, with no key: price.py downloads two public
# offers, AWSBudgets and AWSCostExplorer.
#
# NOT PRODUCED HERE, and said so in the prose: an alert being sent, a budget
# action, activating a cost allocation tag, a Cost Explorer answer with money
# in it, and Cost Anomaly Detection. All need an AWS account with spending.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
WORK=$(mktemp -d)
cd "$WORK" || exit 1
trap 'moto_stop; rm -rf "$WORK"' EXIT
sh_fences "$HERE/budgets.md" 1 | bash -e || exit 1
sh_fences "$HERE/tags.md" 1 | bash -e || exit 1
# the prompt says ~/aws; the files are in the scratch directory, as in ~/aws
ln -s "$HOME/aws/price.py" price.py

block budget
run 'aws sns create-topic --name budget-alerts'
run 'aws budgets create-budget --account-id 123456789012 --budget file://budget.json --notifications-with-subscribers file://notifications.json'
run 'aws budgets describe-budgets --account-id 123456789012'

block notifications
run 'aws budgets describe-notifications-for-budget --account-id 123456789012 --budget-name shop-monthly --output text'
run 'aws budgets describe-subscribers-for-notification --account-id 123456789012 --budget-name shop-monthly --notification NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE 2>&1 | grep ERROR'

block actions
run 'aws budgets describe-budget-actions-for-budget --account-id 123456789012 --budget-name shop-monthly 2>&1 | grep ERROR'

block budgets-price
run 'python3 price.py AWSBudgets 20260911124529 aws-other BudgetsUsage ActionEnabledBudgetsUsage'

block tag-create
run 'aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --output text'
run "aws s3api put-bucket-tagging --bucket shop-assets --tagging 'TagSet=[{Key=project,Value=shop},{Key=env,Value=prod},{Key=team,Value=web}]'"
run 'aws s3api create-bucket --bucket shop-logs --create-bucket-configuration LocationConstraint=sa-east-1 --output text'
run "aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type m7i.large --tag-specifications 'ResourceType=instance,Tags=[{Key=project,Value=shop},{Key=env,Value=prod},{Key=team,Value=web}]' --query 'Instances[0].InstanceId' --output text"
run "aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.medium --query 'Instances[0].InstanceId' --output text"

block tag-find
run "aws resourcegroupstaggingapi get-resources --tag-filters Key=team,Values=web --query 'ResourceTagMappingList[].ResourceARN'"
run "aws resourcegroupstaggingapi get-resources --query 'ResourceTagMappingList[].ResourceARN'"
run "aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId, InstanceType, Tags[?Key==\`team\`].Value | [0]]' --output text"

block tag-fix
run 'aws ec2 create-tags --resources i-5ef280fe00c97d2e5 --tags Key=project,Value=shop Key=env,Value=staging Key=team,Value=data'
run "aws resourcegroupstaggingapi get-resources --tag-filters Key=team --query 'ResourceTagMappingList[].[ResourceARN, Tags[?Key==\`team\`].Value | [0]]' --output text"

block tag-policy
run 'aws organizations create-organization --feature-set ALL --query Organization.Id --output text'
run "aws organizations list-roots --query 'Roots[0].Id' --output text"
run 'aws organizations enable-policy-type --root-id r-k1uz --policy-type TAG_POLICY --query Root.PolicyTypes --output text'
run "aws organizations create-policy --name team-values --type TAG_POLICY --description 'team is web, data or finance' --content file://tag-policy.json --query Policy.PolicySummary.Id --output text"
run 'aws organizations attach-policy --policy-id p-rgyicmvp --target-id r-k1uz'
run "aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.medium --tag-specifications 'ResourceType=instance,Tags=[{Key=team,Value=marketing}]' --query 'Instances[0].Tags' --output text"

block cost-tags
run 'aws ce list-cost-allocation-tags 2>&1 | grep ERROR'

block ce
run 'aws ce get-cost-and-usage --time-period Start=2026-09-01,End=2026-10-01 --granularity MONTHLY --metrics UnblendedCost AmortizedCost NetUnblendedCost --group-by Type=TAG,Key=team'
run 'aws ce get-cost-and-usage --time-period Start=2026-09-01,End=2026-10-01 --granularity DAILY --metrics UnblendedCost --group-by Type=DIMENSION,Key=SERVICE Type=DIMENSION,Key=LINKED_ACCOUNT'

block ce-price
run 'python3 price.py AWSCostExplorer 20260911124538 us-east-1 USE1-APIRequest'

block anomaly
run 'aws ce get-anomaly-monitors 2>&1 | grep ERROR'
