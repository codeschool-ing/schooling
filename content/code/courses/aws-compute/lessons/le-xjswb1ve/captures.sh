#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of aws-compute (spot instances and
# the interruption), as a script that produces them. THE SCRIPT IS THE SOURCE
# AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-xjswb1ve/captures.sh
#
# Everything runs against an EMPTY moto 5.2.3, in the lab lesson 1 builds, in
# one run.
#
# What is STAGED rather than typed:
#   - mixed.json is read out of the example in `mixed-groups`, the same way;
#   - spot-watch.sh is read out of the example in `the-interruption`
#     (from_example), so the file the student copies is the file that ran;
#   - it is run against moto's own port with MD and ONCE set, as the lesson
#     shows. moto has no spot interruption to announce and answers that path
#     with a 500, so only the script's "no notice" branch ran. The branch that
#     drains was not run anywhere.
#
# No spot price here is real: moto's price history is a placeholder, and AWS's
# spot prices are not in the price sheet of lesson 1.
#
# Ids moto invents and the times it prints are whatever this run produced.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/the-interruption.md" spot-watch.sh > spot-watch.sh
from_example "$HERE/mixed-groups.md" mixed.json > mixed.json

block price-history
run 'aws ec2 describe-spot-price-history --instance-types m7i.large --product-descriptions Linux/UNIX --query "SpotPriceHistory[].[AvailabilityZone,SpotPrice,Timestamp]" --output table'

block spot-run
run "aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type m7i.large --instance-market-options '{\"MarketType\": \"spot\", \"SpotOptions\": {\"SpotInstanceType\": \"one-time\", \"InstanceInterruptionBehavior\": \"terminate\"}}' --query 'Instances[].[InstanceId,InstanceType,InstanceLifecycle]' --output text"
run 'aws ec2 describe-spot-instance-requests --query "length(SpotInstanceRequests)"'

block watch
run 'MD=http://localhost:4567 ONCE=1 sh spot-watch.sh'

block rule
run "aws events put-rule --name spot-warning --event-pattern '{\"source\": [\"aws.ec2\"], \"detail-type\": [\"EC2 Spot Instance Interruption Warning\", \"EC2 Instance Rebalance Recommendation\"]}'"

block mixed-create
run "aws ec2 create-launch-template --launch-template-name workers --launch-template-data '{\"ImageId\": \"ami-0629d059c178d0eac\", \"InstanceType\": \"m7i.large\"}' --query LaunchTemplate.LaunchTemplateId --output text"
run "SUBNETS=\$(aws ec2 describe-subnets --query 'join(\`,\`, Subnets[].SubnetId)' --output text)"
run "aws autoscaling create-auto-scaling-group --auto-scaling-group-name workers --min-size 0 --max-size 20 --desired-capacity 10 --vpc-zone-identifier \"\$SUBNETS\" --capacity-rebalance --mixed-instances-policy file://mixed.json"

block mixed-describe
run 'aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names workers --query "AutoScalingGroups[].{rebalance: CapacityRebalance, distribution: MixedInstancesPolicy.InstancesDistribution, types: MixedInstancesPolicy.LaunchTemplate.Overrides[].InstanceType}"'
run 'aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=workers --query "Reservations[].Instances[].[InstanceType,InstanceLifecycle]" --output text | sort | uniq -c'

block hook
run 'aws autoscaling put-lifecycle-hook --auto-scaling-group-name workers --lifecycle-hook-name drain --lifecycle-transition autoscaling:EC2_INSTANCE_TERMINATING --heartbeat-timeout 120 --default-result CONTINUE'
run 'aws autoscaling describe-lifecycle-hooks --auto-scaling-group-name workers'
