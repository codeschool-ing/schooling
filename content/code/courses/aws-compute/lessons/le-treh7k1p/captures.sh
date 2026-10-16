#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of aws-compute (ECS: task
# definitions, tasks, services and clusters), as a script that produces them.
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-treh7k1p/captures.sh            # everything against moto
#   LAB_HOSTS=1 bash lessons/le-treh7k1p/captures.sh docker
#                                                   # the container, for real
#
# The moto part runs against an empty moto 5.2.3. moto keeps ECS's records and
# runs no container: a task it reports RUNNING has nothing behind it, and a
# service starts no tasks. The lesson says so where it quotes them.
#
# The `docker` part runs nginx:1.29-alpine with the real Docker of the docker
# course, on the machine's own network (a published port is not reachable from
# inside a network namespace). The image was pulled once by the lab through
# mirror.gcr.io and tagged with the name the lesson uses; the student pulls it
# from Docker Hub with `docker pull nginx:1.29-alpine`.
#
# What is STAGED rather than typed:
#   - prices.py is read out of lesson 1's `the-price-sheet`, as the student
#     saved it there, and answers from the price cache that lesson filled;
#   - web.json is read out of the schooling-example in `task-definitions`;
#   - `register-container-instance` is called by hand with an identity
#     document naming the instance. On AWS the ECS agent on the instance makes
#     that call itself when it starts; moto has no agent, and the lesson says
#     the call is the agent's;
#   - the auto scaling group behind the capacity provider is created quietly
#     (lesson 4 is where groups are built), and the group's ARN is read from
#     moto.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

if [ "${1:-}" = docker ]; then
  quiet 'docker rm -f web web2'
  block docker-image
  run 'docker image ls nginx:1.29-alpine --format "{{.Repository}}:{{.Tag}}  {{.Size}}"'
  block docker-run
  run 'docker run -d --name web -p 8080:80 -e SHOP_ENV=staging --cpu-shares 256 --memory 512m nginx:1.29-alpine | cut -c1-12'
  run 'docker ps --format "{{.Names}}  {{.Image}}  {{.Ports}}"'
  quiet 'sleep 1'
  run 'curl -s localhost:8080 | grep -o "<title>.*</title>"'
  block docker-inspect
  run 'docker exec web printenv SHOP_ENV'
  run 'docker inspect --format "{{.HostConfig.CpuShares}} {{.HostConfig.Memory}}" web'
  run 'docker logs web 2>/dev/null | tail -1 | cut -c1-80'
  block docker-port
  run 'docker run -d --name web2 -p 8080:80 nginx:1.29-alpine > /dev/null'
  run 'docker ps -a --filter name=web2 --format "{{.Names}}  {{.Status}}"'
  block docker-essential
  run 'docker stop web'
  run 'docker ps -a --filter name=web --format "{{.Names}}  {{.Status}}"'
  quiet 'docker rm -f web web2'
  exit 0
fi

from_example "$HERE/task-definitions.md" web.json > web.json
from_example "$HERE/../le-ps61q5st/the-price-sheet.md" prices.py > prices.py

block roles
put trust.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON
put execution.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
JSON
run 'aws iam create-role --role-name web-execution --assume-role-policy-document file://trust.json --query Role.Arn --output text'
run 'aws iam put-role-policy --role-name web-execution --policy-name pull-and-log --policy-document file://execution.json'
run 'aws iam create-role --role-name web-task --assume-role-policy-document file://trust.json --query Role.Arn --output text'
run 'aws iam attach-role-policy --role-name web-execution --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy'

block register
run 'aws ecs register-task-definition --cli-input-json file://web.json --query "taskDefinition.[taskDefinitionArn,revision,status]"'
run 'aws ecs register-task-definition --cli-input-json file://web.json --query taskDefinition.taskDefinitionArn --output text'
run 'aws ecs list-task-definitions --family-prefix web'
run 'aws ecs deregister-task-definition --task-definition web:1 --query taskDefinition.status --output text'
run 'aws ecs describe-task-definition --task-definition web --query "taskDefinition.[revision,containerDefinitions[0].image]" --output text'

block cluster
run 'aws ecs create-cluster --cluster-name shop --query "cluster.[clusterName,status,registeredContainerInstancesCount]" --output text'
run 'AMI=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-ecs-hvm-*-x86_64" --query "sort_by(Images,&Name)[-1].ImageId" --output text)'
run 'aws ec2 describe-images --image-ids "$AMI" --query "Images[0].Name" --output text'
run 'ID=$(aws ec2 run-instances --image-id "$AMI" --instance-type m7i.large --user-data "#!/bin/bash
echo ECS_CLUSTER=shop >> /etc/ecs/ecs.config" --query "Instances[0].InstanceId" --output text)'
run 'aws ecs register-container-instance --cluster shop --instance-identity-document "{\"instanceId\":\"$ID\",\"availabilityZone\":\"sa-east-1a\"}" --query "containerInstance.[ec2InstanceId,status]" --output text'
run 'CI=$(aws ecs list-container-instances --cluster shop --query "containerInstanceArns[0]" --output text)'
run 'aws ecs describe-container-instances --cluster shop --container-instances "$CI" --query "containerInstances[0].remainingResources[?name==\`CPU\`||name==\`MEMORY\`].[name,integerValue]" --output text'

block run-task
run 'aws ecs run-task --cluster shop --task-definition web --query "tasks[0].[lastStatus,containers[0].lastStatus]" --output text'
run 'aws ecs describe-container-instances --cluster shop --container-instances "$CI" --query "containerInstances[0].[runningTasksCount,remainingResources[?name==\`CPU\`||name==\`MEMORY\`].integerValue]" --output text'

block port-taken
run 'aws ecs run-task --cluster shop --task-definition web --query "{tasks: length(tasks), failures: failures}"'
run 'aws ecs describe-container-instances --cluster shop --container-instances "$CI" --query "containerInstances[0].remainingResources[?name==\`PORTS\`].stringSetValue[]" --output text'

block service
run 'aws ecs create-service --cluster shop --service-name web --task-definition web:2 --desired-count 3 --deployment-configuration minimumHealthyPercent=50,maximumPercent=200 --query "service.[desiredCount,runningCount,pendingCount]" --output text'
run 'aws ecs list-tasks --cluster shop --query "length(taskArns)"'
run 'aws ecs describe-services --cluster shop --services web --query "services[0].deploymentConfiguration"'

block deploy
run 'aws ecs register-task-definition --cli-input-json file://web.json --query taskDefinition.revision'
run 'aws ecs update-service --cluster shop --service web --task-definition web:3 --query "service.[taskDefinition,deployments[].[status,taskDefinition]]" --output text'

block delete
run 'aws ecs delete-service --cluster shop --service web'
run 'aws ecs update-service --cluster shop --service web --desired-count 0 --query service.desiredCount'
run 'aws ecs delete-service --cluster shop --service web --query service.status --output text'

block capacity
quiet 'aws ec2 create-launch-template --launch-template-name ecs-web --launch-template-data "{\"ImageId\":\"$AMI\",\"InstanceType\":\"m7i.large\"}"'
quiet 'aws autoscaling create-auto-scaling-group --auto-scaling-group-name ecs-web --launch-template LaunchTemplateName=ecs-web --min-size 0 --max-size 4 --availability-zones sa-east-1a'
run 'ASG=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ecs-web --query "AutoScalingGroups[0].AutoScalingGroupARN" --output text)'
run 'aws ecs create-capacity-provider --name ecs-web --auto-scaling-group-provider "autoScalingGroupArn=$ASG,managedScaling={status=ENABLED,targetCapacity=90},managedTerminationProtection=DISABLED" --query "capacityProvider.[name,status,autoScalingGroupProvider.managedScaling.targetCapacity]" --output text'
run 'aws ecs put-cluster-capacity-providers --cluster shop --capacity-providers ecs-web FARGATE FARGATE_SPOT --default-capacity-provider-strategy capacityProvider=ecs-web,base=1,weight=1 --query "cluster.[capacityProviders,defaultCapacityProviderStrategy]"'

block price
run 'python3 prices.py ec2 | grep -E "m7i.large|m7g.large"'
