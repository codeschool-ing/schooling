#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# canary.py is read out of the section what-a-canary-catches, so the program
# that ran is the one the student reads. It is a model and the lesson says so.
# There is no ECS cluster, load balancer or role behind the deployment group:
# moto records the group without checking that any of them exists.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf deploy && mkdir deploy && cd deploy || exit 1
moto_up
student_env

put deployment-group.json <<'EOF2'
{
  "applicationName": "shop-api",
  "deploymentGroupName": "prod",
  "serviceRoleArn": "arn:aws:iam::123456789012:role/shop-deploy",
  "deploymentConfigName": "CodeDeployDefault.ECSCanary10Percent5Minutes",
  "deploymentStyle": {
    "deploymentType": "BLUE_GREEN",
    "deploymentOption": "WITH_TRAFFIC_CONTROL"
  },
  "ecsServices": [{ "clusterName": "shop", "serviceName": "api" }],
  "loadBalancerInfo": {
    "targetGroupPairInfoList": [{
      "targetGroups": [{ "name": "api-blue" }, { "name": "api-green" }],
      "prodTrafficRoute": { "listenerArns": ["arn:aws:elasticloadbalancing:sa-east-1:123456789012:listener/app/shop/5f2a/443a"] },
      "testTrafficRoute": { "listenerArns": ["arn:aws:elasticloadbalancing:sa-east-1:123456789012:listener/app/shop/5f2a/8443"] }
    }]
  },
  "blueGreenDeploymentConfiguration": {
    "deploymentReadyOption": { "actionOnTimeout": "CONTINUE_DEPLOYMENT" },
    "terminateBlueInstancesOnDeploymentSuccess": {
      "action": "TERMINATE",
      "terminationWaitTimeInMinutes": 60
    }
  },
  "alarmConfiguration": {
    "enabled": true,
    "alarms": [{ "name": "api-green-5xx" }, { "name": "api-green-p99" }]
  },
  "autoRollbackConfiguration": {
    "enabled": true,
    "events": ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }
}
EOF2
block group
run 'aws deploy create-application --application-name shop-api --compute-platform ECS --query applicationId --output text'
run 'aws deploy create-deployment-group --cli-input-json file://deployment-group.json --query deploymentGroupId --output text'
run "aws deploy get-deployment-group --application-name shop-api --deployment-group-name prod --query 'deploymentGroupInfo.[deploymentConfigName,autoRollbackConfiguration.events,alarmConfiguration]'"

put appspec.yaml <<'EOF2'
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "arn:aws:ecs:sa-east-1:123456789012:task-definition/shop-api:42"
        LoadBalancerInfo:
          ContainerName: "api"
          ContainerPort: 8080
Hooks:
  - AfterAllowTestTraffic: "arn:aws:lambda:sa-east-1:123456789012:function:shop-smoke-test"
EOF2
block deploy
quiet "python3 -c \"import json; print(json.dumps({'revisionType': 'AppSpecContent', 'appSpecContent': {'content': open('appspec.yaml').read()}}))\" > revision.json"
run 'DEPLOYMENT=$(aws deploy create-deployment --application-name shop-api --deployment-group-name prod --revision file://revision.json --query deploymentId --output text); echo "$DEPLOYMENT"'
DEPLOYMENT=$(aws deploy list-deployments --query 'deployments[0]' --output text)
sleep 2
run "aws deploy get-deployment --deployment-id $DEPLOYMENT --query 'deploymentInfo.[status,deploymentConfigName,deploymentOverview]'"

from_lesson "$HERE/what-a-canary-catches.md" canary.py > canary.py
block canary
run 'python3 canary.py'
