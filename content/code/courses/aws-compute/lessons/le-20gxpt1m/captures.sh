#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of aws-compute (Fargate), as a
# script that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT
# COMMITTED.
#
#   bash lessons/le-20gxpt1m/captures.sh            # everything against moto
#   LAB_HOSTS=1 bash lessons/le-20gxpt1m/captures.sh docker
#                                                   # SIGTERM, for real
#
# The moto part runs against an empty moto 5.2.3. moto keeps ECS's records and
# runs no container. Its RunTask fails with an internal error for every task
# in `awsvpc` mode given a real subnet (moto 5.2.3 reads a field its own
# network interface does not have), after it has created the task's network
# interface; the lesson quotes the failure and the interface, and says the
# error is moto's. AWS_MAX_ATTEMPTS=1 on that one command stops the CLI
# retrying, so one call leaves one interface; the student types it too.
#
# The `docker` part runs nginx:1.29-alpine's shell with the real Docker of the
# docker course, to show a container receiving SIGTERM and finishing its work
# inside the stop timeout. The image was pulled once by the lab, as in lesson 8.
#
# What is STAGED rather than typed:
#   - fargate.json and fargate_cost.py are read out of the schooling-examples
#     in `awsvpc` and `sizes-and-price`;
#   - prices.py is read out of lesson 1's `the-price-sheet` and answers from
#     the price cache that lesson filled.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

if [ "${1:-}" = docker ]; then
  quiet 'docker rm -f job'
  block stopsignal
  run 'docker image inspect --format "{{.Config.StopSignal}}" nginx:1.29-alpine'
  block sigterm
  run 'docker run -d --name job --stop-signal SIGTERM nginx:1.29-alpine sh -c "trap '"'"'echo SIGTERM: saving; sleep 3; echo saved, exiting; exit 0'"'"' TERM; echo working; while true; do sleep 1; done" > /dev/null'
  quiet 'sleep 2'
  run 'time docker stop -t 120 job'
  run 'docker logs job'
  run 'docker inspect --format "{{.State.ExitCode}}" job'
  block sigkill
  quiet 'docker rm -f job'
  run 'docker run -d --name job --stop-signal SIGTERM nginx:1.29-alpine sh -c "trap '"'"'echo SIGTERM: saving; sleep 30; echo saved'"'"' TERM; while true; do sleep 1; done" > /dev/null'
  quiet 'sleep 2'
  run 'time docker stop -t 5 job'
  run 'docker logs job'
  run 'docker inspect --format "{{.State.ExitCode}}" job'
  quiet 'docker rm -f job'
  exit 0
fi

from_example "$HERE/awsvpc.md" fargate.json > fargate.json
from_example "$HERE/sizes-and-price.md" fargate_cost.py > fargate_cost.py
from_example "$HERE/../le-ps61q5st/the-price-sheet.md" prices.py > prices.py

block network
run 'VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)'
run 'SUBNET=$(aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)'
run 'SG=$(aws ec2 create-security-group --group-name web-task --description "web tasks" --vpc-id "$VPC" --query GroupId --output text)'
run 'aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 80 --cidr 10.0.0.0/16 --query Return'
run 'aws ecs create-cluster --cluster-name shop --query cluster.status --output text'

block register
run 'aws ecs register-task-definition --cli-input-json file://fargate.json --query "taskDefinition.[revision,networkMode,cpu,memory,runtimePlatform.cpuArchitecture]" --output text'
run 'aws ecs describe-task-definition --task-definition web-fargate --query "taskDefinition.[requiresCompatibilities,compatibilities]" --output text'

block run-task
run 'AWS_MAX_ATTEMPTS=1 aws ecs run-task --cluster shop --task-definition web-fargate --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=DISABLED}" 2>&1 | head -2 | cut -c1-90'
run 'aws ec2 describe-network-interfaces --filters "Name=subnet-id,Values=$SUBNET" --query "NetworkInterfaces[].[NetworkInterfaceId,PrivateIpAddress,Groups[0].GroupId,Description]" --output text'

block no-network
run 'aws ecs run-task --cluster shop --task-definition web-fargate --launch-type FARGATE'

block service
run 'aws ecs create-service --cluster shop --service-name web --task-definition web-fargate --desired-count 2 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=DISABLED}" --query "service.[launchType,desiredCount,runningCount]" --output text'

block bad-size
run 'aws ecs register-task-definition --family odd-size --network-mode awsvpc --requires-compatibilities FARGATE --cpu 256 --memory 4096 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":512}]" --query "taskDefinition.[family,cpu,memory]" --output text'

block price
run 'python3 prices.py containers | sed -n 3,8p'
block cost
run 'python3 fargate_cost.py'

block spot
run 'aws ecs put-cluster-capacity-providers --cluster shop --capacity-providers FARGATE FARGATE_SPOT --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 --query "cluster.capacityProviders" --output text'
run 'aws ecs create-service --cluster shop --service-name worker --task-definition web-fargate --desired-count 5 --capacity-provider-strategy capacityProvider=FARGATE,base=1,weight=1 capacityProvider=FARGATE_SPOT,weight=3 --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG]}" --query "service.[serviceName,desiredCount,capacityProviderStrategy]" --output text'

block give-up
run 'aws ecs register-task-definition --family root --network-mode awsvpc --requires-compatibilities FARGATE --cpu 256 --memory 512 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":512,\"privileged\":true}]" --query "taskDefinition.[family,revision]" --output text'
run 'aws ecs register-task-definition --family bridged --network-mode bridge --requires-compatibilities FARGATE --cpu 256 --memory 512 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":512}]" --query "taskDefinition.[family,networkMode]" --output text'
run 'aws ecs register-task-definition --family big-disk --network-mode awsvpc --requires-compatibilities FARGATE --cpu 1024 --memory 2048 --ephemeral-storage sizeInGiB=500 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":2048}]" --query "taskDefinition.[family,ephemeralStorage.sizeInGiB]" --output text'
