#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of aws-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-n7yz3p6x/captures.sh
#   LAB_HOSTS=1 bash lessons/le-n7yz3p6x/captures.sh prices
#
# NOTHING ABOUT APP RUNNER WAS RUN. moto 5.2.3 has no App Runner: the one call
# shown is there to show the 500 it answers. The skeleton of create-service is
# printed by the AWS CLI on the laptop, from its own model of the API, and
# reaches nobody. Everything the lesson says about App Runner's behaviour is
# from AWS's documentation, which the lesson says in its prose.
#
# Elastic Beanstalk is answered by moto, which keeps an application and an
# environment as records and creates nothing behind them; the lesson shows the
# empty EC2, Auto Scaling and load balancer listings that prove it.
#
# What is STAGED rather than typed:
#   - moto is started by the lab before the first command, as lesson 1's
#     section `your-lab` starts it, in a terminal of the student's own;
#   - `prices` reads prices.py out of the example in lesson 1's section
#     `the-price-sheet`. It reads the cached price files, and downloads one
#     only if the cache lacks it, through the recording machine's proxy
#     (HTTPS_PROXY), as lesson 1's `prices` does.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
LESSON1=$HERE/../le-ps61q5st

if [ "${1:-}" = prices ]; then
  export HTTPS_PROXY=$LAB_PROXY
  from_example "$LESSON1/the-price-sheet.md" prices.py > prices.py
  block apprunner-sheet
  run 'python3 prices.py containers | tail -n 3'
  run 'jq -r '\''.terms.OnDemand[][].priceDimensions[] | "\(.pricePerUnit.USD)\t\(.unit)\t\(.description)"'\'' ~/.cache/aws-prices/AWSAppRunner-*.json | sort'
  exit 0
fi

block apprunner-moto
run 'aws apprunner list-services --region us-east-1'

block express-skeleton
run 'aws ecs create-express-gateway-service --generate-cli-skeleton | jq -c keys'
# not quoted: the lesson only says that moto answers this with a 500
run 'aws ecs create-express-gateway-service --execution-role-arn arn:aws:iam::123456789012:role/run --infrastructure-role-arn arn:aws:iam::123456789012:role/infra --primary-container image=nginx:1.29-alpine'

block apprunner-skeleton
run 'aws apprunner create-service --generate-cli-skeleton | jq '\''{ServiceName, SourceConfiguration: (.SourceConfiguration | keys), InstanceConfiguration: (.InstanceConfiguration | del(.InstanceRoleArn))}'\'''

block eb-stacks
run 'aws elasticbeanstalk list-available-solution-stacks --query "length(SolutionStacks)"'
run 'aws elasticbeanstalk list-available-solution-stacks --query "SolutionStacks[?contains(@, \`Python\`)]"'

block eb-create
run 'aws elasticbeanstalk create-application --application-name shop --description "the shop web app"'
run 'aws elasticbeanstalk create-environment --application-name shop --environment-name shop-prod --solution-stack-name "64bit Amazon Linux 2023 v4.6.0 running Python 3.12"'

block eb-nothing-behind
run 'aws ec2 describe-instances --query "Reservations[].Instances[].InstanceId"'
run 'aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[].AutoScalingGroupName"'
run 'aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName"'
run 'aws cloudformation list-stacks --query "StackSummaries[].StackName"'

block eb-version
run 'aws elasticbeanstalk create-application-version --application-name shop --version-label v2'
