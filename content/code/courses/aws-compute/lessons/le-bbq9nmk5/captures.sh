#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of aws-compute (launch templates and
# auto scaling groups), as a script that produces them. THE SCRIPT IS THE SOURCE
# AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-bbq9nmk5/captures.sh
#
# Everything runs against an EMPTY moto 5.2.3, in the lab lesson 1 builds. One
# run records every block, in order, because each block builds on the last: the
# template of `launch-templates` is the one the group of `the-group` launches
# from, and so on to `instance-refresh`.
#
# What is STAGED rather than typed:
#   - template.json is read out of the example in `launch-templates`
#     (from_example), so the file the student copies is the file that was used;
#   - nothing else. Every command below is one the lesson shows.
#
# Ids moto invents (templates, subnets, instances, the group's ARN) and the
# times it prints are whatever this run produced.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/launch-templates.md" template.json > template.json

block lt-create
run 'aws ec2 describe-images --image-ids ami-0629d059c178d0eac --query "Images[].[Name,Architecture]" --output text'
run 'aws ec2 create-launch-template --launch-template-name web --version-description "t3.micro, first" --launch-template-data file://template.json'

block lt-source-version
run "aws ec2 create-launch-template-version --launch-template-name web --source-version 1 --version-description t3.medium --launch-template-data '{\"InstanceType\": \"t3.medium\"}' --query LaunchTemplateVersion.VersionNumber"
run 'aws ec2 describe-launch-template-versions --launch-template-name web --versions 2 --query "LaunchTemplateVersions[].LaunchTemplateData"'

block lt-whole
run "jq '.InstanceType = \"t3.medium\"' template.json > template-medium.json"
run 'aws ec2 create-launch-template-version --launch-template-name web --version-description "t3.medium, whole" --launch-template-data file://template-medium.json --query LaunchTemplateVersion.VersionNumber'
run 'aws ec2 describe-launch-templates --launch-template-names web --query "LaunchTemplates[].[DefaultVersionNumber,LatestVersionNumber]" --output text'

block group-create
run "SUBNETS=\$(aws ec2 describe-subnets --query 'join(\`,\`, Subnets[].SubnetId)' --output text)"
run 'echo "$SUBNETS"'
run "aws autoscaling create-auto-scaling-group --auto-scaling-group-name web --launch-template 'LaunchTemplateName=web,Version=\$Default' --min-size 2 --max-size 6 --desired-capacity 3 --vpc-zone-identifier \"\$SUBNETS\""
run 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].{min: MinSize, max: MaxSize, desired: DesiredCapacity, template: LaunchTemplate.Version, zones: AvailabilityZones}"'
run 'aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,LifecycleState,HealthStatus,LaunchTemplate.Version]" --output table'

block group-tags
run 'aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=web --query "Reservations[0].Instances[0].Tags" --output table'

block group-desired
run 'aws autoscaling set-desired-capacity --auto-scaling-group-name web --desired-capacity 5'
run 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text'
run 'aws autoscaling set-desired-capacity --auto-scaling-group-name web --desired-capacity 8'
run 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[MaxSize,DesiredCapacity,length(Instances)]" --output text'
run 'aws autoscaling set-desired-capacity --auto-scaling-group-name web --desired-capacity 3'

block zones
run 'aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=web Name=instance-state-name,Values=running --query "Reservations[].Instances[].[InstanceId,Placement.AvailabilityZone,SubnetId]" --output table'

block health
run 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[HealthCheckType,HealthCheckGracePeriod]" --output text'
SICK=$(aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[0].InstanceId' --output text)
run "aws autoscaling set-instance-health --instance-id $SICK --health-status Unhealthy"
run 'aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,HealthStatus]" --output text'
run "aws autoscaling terminate-instance-in-auto-scaling-group --instance-id $SICK --no-should-decrement-desired-capacity --query 'Activity.[StatusCode,Cause]' --output text"
run 'aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,HealthStatus]" --output text'

block refresh-default
run 'aws ec2 modify-launch-template --launch-template-name web --default-version 3 --query LaunchTemplate.DefaultVersionNumber'
run 'aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,InstanceType]" --output text'

block refresh-start
run "aws autoscaling start-instance-refresh --auto-scaling-group-name web --preferences '{\"MinHealthyPercentage\": 90, \"InstanceWarmup\": 120, \"SkipMatching\": true}'"

block refresh-by-hand
OLD=$(aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[0].InstanceId' --output text)
run "aws autoscaling terminate-instance-in-auto-scaling-group --instance-id $OLD --no-should-decrement-desired-capacity --query Activity.StatusCode --output text"
run 'aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,InstanceType]" --output text'
