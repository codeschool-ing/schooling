#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of aws-compute (scaling by metric,
# by schedule and by prediction), as a script that produces them. THE SCRIPT IS
# THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-v7tj3ctp/captures.sh
#
# Everything runs against an EMPTY moto 5.2.3, in the lab lesson 1 builds, in
# one run: the group of `target-tracking` is the one every later block scales.
#
# What is STAGED rather than typed: nothing. The template and the group are
# made by the commands the first block shows, which are lesson 4's with a
# smaller output.
#
# moto keeps no metrics, so no alarm here ever changes state by itself and no
# policy ever runs on its own. What the lesson says about policies acting on
# a metric, about scheduled actions firing and about forecasts is AWS's
# documented behaviour, and the prose says that it was not run.
#
# Ids moto invents and the times it prints are whatever this run produced.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

block setup
run "aws ec2 create-launch-template --launch-template-name web --launch-template-data '{\"ImageId\": \"ami-0629d059c178d0eac\", \"InstanceType\": \"t3.micro\"}' --query LaunchTemplate.LaunchTemplateId --output text"
run "SUBNETS=\$(aws ec2 describe-subnets --query 'join(\`,\`, Subnets[].SubnetId)' --output text)"
run "aws autoscaling create-auto-scaling-group --auto-scaling-group-name web --launch-template 'LaunchTemplateName=web,Version=\$Default' --min-size 2 --max-size 12 --desired-capacity 2 --vpc-zone-identifier \"\$SUBNETS\" --default-instance-warmup 180"

block tt-put
run "aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name cpu-50 --policy-type TargetTrackingScaling --target-tracking-configuration '{\"PredefinedMetricSpecification\": {\"PredefinedMetricType\": \"ASGAverageCPUUtilization\"}, \"TargetValue\": 50}'"
run 'aws autoscaling describe-policies --auto-scaling-group-name web --policy-names cpu-50'
run 'aws cloudwatch describe-alarms'

block simple
run 'aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name add-two --policy-type SimpleScaling --adjustment-type ChangeInCapacity --scaling-adjustment 2 --cooldown 300'
run 'aws autoscaling execute-policy --auto-scaling-group-name web --policy-name add-two'
run 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text'
run 'aws autoscaling execute-policy --auto-scaling-group-name web --policy-name add-two --honor-cooldown'
run 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text'

block step
run 'aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name cpu-steps --policy-type StepScaling --adjustment-type ChangeInCapacity --metric-aggregation-type Average --step-adjustments MetricIntervalLowerBound=0,MetricIntervalUpperBound=20,ScalingAdjustment=1 MetricIntervalLowerBound=20,ScalingAdjustment=3'
run 'aws autoscaling execute-policy --auto-scaling-group-name web --policy-name cpu-steps --metric-value 85 --breach-threshold 60'

block alarm
run "STEPS=\$(aws autoscaling describe-policies --auto-scaling-group-name web --policy-names cpu-steps --query 'ScalingPolicies[0].PolicyARN' --output text)"
run 'aws cloudwatch put-metric-alarm --alarm-name web-cpu-high --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=AutoScalingGroupName,Value=web --statistic Average --period 60 --evaluation-periods 3 --threshold 60 --comparison-operator GreaterThanThreshold --alarm-actions "$STEPS"'
run 'aws cloudwatch set-alarm-state --alarm-name web-cpu-high --state-value ALARM --state-reason "set by hand to see what follows"'
run 'aws cloudwatch describe-alarms --alarm-names web-cpu-high --query "MetricAlarms[].[StateValue,StateReason]" --output text'
run 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text'

block scheduled
run "date -u -d 'TZ=\"America/Sao_Paulo\" 2026-10-19 07:30'"
run "aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name web --scheduled-action-name weekday-morning --recurrence '30 7 * * 1-5' --time-zone America/Sao_Paulo --min-size 6 --desired-capacity 6"
run "aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name web --scheduled-action-name weekday-evening --recurrence '0 19 * * 1-5' --time-zone America/Sao_Paulo --min-size 2 --desired-capacity 2"
run 'aws autoscaling describe-scheduled-actions --auto-scaling-group-name web'

block predictive
run "aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name forecast --policy-type PredictiveScaling --predictive-scaling-configuration '{\"MetricSpecifications\": [{\"TargetValue\": 50, \"PredefinedMetricPairSpecification\": {\"PredefinedMetricType\": \"ASGCPUUtilization\"}}], \"Mode\": \"ForecastOnly\"}'"
run 'aws autoscaling get-predictive-scaling-forecast --auto-scaling-group-name web --policy-name forecast --start-time 2026-10-19T00:00:00Z --end-time 2026-10-20T00:00:00Z'

block warmup
run 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].{grace: HealthCheckGracePeriod, warmup: DefaultInstanceWarmup, cooldown: DefaultCooldown}"'
