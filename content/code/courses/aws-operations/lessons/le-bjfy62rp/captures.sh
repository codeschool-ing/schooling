#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# The load balancer is made by the lesson's own fence (subscribing.md, the
# first sh fence). The subscription is moto's and bills nothing; the price
# list is AWS's, at pinned versions.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf shield && mkdir shield && cd shield || exit 1
moto_up
student_env
fence "$HERE/subscribing.md" 1

block before
run 'LB=$(aws elbv2 describe-load-balancers --names shop --query "LoadBalancers[0].LoadBalancerArn" --output text)'
run 'aws shield describe-subscription'
block subscribe
run 'aws shield create-subscription'
run "aws shield describe-subscription --query 'Subscription.[StartTime,EndTime,TimeCommitmentInSeconds,AutoRenew]' --output text"
block protect
run 'aws shield create-protection --name shop-alb --resource-arn $LB'
run "aws shield list-protections --query 'Protections[].[Name,ResourceArn]' --output text"
block cancel
run 'aws shield delete-subscription 2>&1 | grep -m1 ERROR'
run 'aws shield list-attacks 2>&1 | grep -m1 ERROR'

cd "$HOME/aws" || exit 1
block prices
run 'python3 price.py AWSShield ELB'
run "curl -sS https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSShield/20260916132208/aws-other/index.json | jq -r '.terms.OnDemand[][].priceDimensions[] | select(.description | test(\"Subscription\")) | [.pricePerUnit.USD, .unit, .description] | @tsv'"
run 'python3 price.py awswaf SAE1-ShieldProtected-RequestV2-Tier1'
