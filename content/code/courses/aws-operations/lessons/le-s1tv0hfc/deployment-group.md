---
title: The deployment group, and what moto forgot
version: 1
---

CodeDeploy is organised in two levels. An **application** is a name. A **deployment group** under it
says where and how: which ECS service, which load balancer and target groups, which strategy, which
alarms stop a deployment, and what happens when one is stopped. The deployment group is where a
rollback is designed, so it is worth reading slowly.

```json
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
```

The pieces, in the order a deployment meets them:

- **`targetGroupPairInfoList`** names the two target groups, `api-blue` and `api-green`, and two
  listeners. The **production** listener, on 443, is what customers reach. The **test** listener, on
  8443, reaches green alone, before any customer does, which is what a smoke test runs against.
- **`deploymentReadyOption`** says what happens when green is healthy: continue at once, or wait for a
  person to press continue, up to a time limit.
- **`deploymentConfigName`** is the strategy from the previous section.
- **`alarmConfiguration`** lists CloudWatch alarms. If any of them goes into `ALARM` while the
  deployment runs, CodeDeploy stops it.
- **`autoRollbackConfiguration`** says that a failure, or a stop caused by an alarm, moves the traffic
  back to blue on its own.
- **`terminationWaitTimeInMinutes`** keeps blue running for an hour after success. For that hour a
  rollback is still a listener move; after it, blue is gone and a rollback is a new deployment.

## Ask what was stored

```
ana@laptop:~/aws/deploy$ aws deploy create-application --application-name shop-api --compute-platform ECS --query applicationId --output text
2c031cba-9f6c-4da5-8236-f2caf533d918
ana@laptop:~/aws/deploy$ aws deploy create-deployment-group --cli-input-json file://deployment-group.json --query deploymentGroupId --output text
548573b0-30f3-4e71-815e-6fc08cb52c49
ana@laptop:~/aws/deploy$ aws deploy get-deployment-group --application-name shop-api --deployment-group-name prod --query 'deploymentGroupInfo.[deploymentConfigName,autoRollbackConfiguration.events,alarmConfiguration]'
[
    "CodeDeployDefault.ECSCanary10Percent5Minutes",
    [
        "DEPLOYMENT_FAILURE",
        "DEPLOYMENT_STOP_ON_ALARM"
    ],
    {}
]
```

moto accepted the group and returned an id, and then, asked to read it back, returned the strategy and
the rollback events and **an empty `alarmConfiguration`**. The two alarms are gone. moto does not keep
that field, and nothing in its answer to `create-deployment-group` said so.

On AWS the same mistake happens a different way: an alarm name with a typo, or an alarm created in
another region, is accepted, and the group then watches an alarm that does not exist and never fires.
**Either way the lesson is the same: read the configuration back and compare it with what you
meant**, because a rollback that depends on an alarm is only as real as the alarm. Lesson 4 turns that
comparison into a habit, under the name drift.

## A deployment

The deployment itself names an **AppSpec**, which tells CodeDeploy which task definition to run
and which hooks to call:

```yaml
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
```

The hook `AfterAllowTestTraffic` runs a Lambda function once the test listener reaches green, and the
deployment continues only if the function reports success. That is the smoke test, run against the
new version before a single customer request reaches it.

```
ana@laptop:~/aws/deploy$ DEPLOYMENT=$(aws deploy create-deployment --application-name shop-api --deployment-group-name prod --revision file://revision.json --query deploymentId --output text); echo "$DEPLOYMENT"
16fc6244-e1b1-4876-b5ca-d8fbb46d84a2
ana@laptop:~/aws/deploy$ aws deploy get-deployment --deployment-id 16fc6244-e1b1-4876-b5ca-d8fbb46d84a2 --query 'deploymentInfo.[status,deploymentConfigName,deploymentOverview]'
[
    "Created",
    "CodeDeployDefault.ECSCanary10Percent5Minutes",
    {
        "Pending": 0,
        "InProgress": 0,
        "Succeeded": 0,
        "Failed": 0,
        "Skipped": 0,
        "Ready": 0
    }
]
```

`Created`, with every counter at zero, and it will stay there: moto records the deployment and runs
nothing, so **no traffic moved, no hook ran and no alarm was consulted**. On AWS the same command
would start green, run the hook, shift 10% of production, wait five minutes, and shift the rest.
