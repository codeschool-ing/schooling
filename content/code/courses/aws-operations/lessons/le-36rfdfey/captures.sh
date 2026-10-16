#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# The resources are made by the lesson's own fence (nobody.md, the first sh
# fence), and so is bill.csv (the-bill.md, the first sh fence): a made-up
# month, abridged to four of the Cost and Usage Report's columns. moto has no
# cost data. owners.py, bill.py and team.json are read out of the lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf owners && mkdir owners && cd owners || exit 1
moto_up
student_env
from_lesson "$HERE/nobody.md" owners.py > owners.py
from_lesson "$HERE/the-bill.md" bill.py > bill.py
from_lesson "$HERE/categories.md" team.json > team.json
fence "$HERE/nobody.md" 1

block owners
run 'python3 owners.py'
block tagging-api
run "aws resourcegroupstaggingapi get-resources --query 'ResourceTagMappingList[].ResourceARN' --output text | tr '\t' '\n'"
block fix
run 'aws resourcegroupstaggingapi tag-resources --resource-arn-list arn:aws:dynamodb:sa-east-1:123456789012:table/carts --tags owner=checkout,environment=prod --query FailedResourcesMap'
run 'python3 owners.py | grep carts'

block allocation
run 'aws ce update-cost-allocation-tags-status --cost-allocation-tags-status TagKey=owner,Status=Active 2>&1 | grep -m1 ERROR'

fence "$HERE/the-bill.md" 1
block bill
run 'python3 bill.py'

block category
run 'CATEGORY=$(aws ce create-cost-category-definition --cli-input-json file://team.json --query CostCategoryArn --output text); echo $CATEGORY'
run "aws ce describe-cost-category-definition --cost-category-arn \$CATEGORY --query 'CostCategory.[Name,EffectiveStart,DefaultValue,SplitChargeRules[0].Method]' --output text"
run 'aws ce list-cost-category-definitions 2>&1 | grep -m1 ERROR'
