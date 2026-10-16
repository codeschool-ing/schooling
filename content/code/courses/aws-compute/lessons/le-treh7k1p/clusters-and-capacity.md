---
title: "Clusters and capacity: where the tasks land"
version: 1
---

The word cluster suggests a set of machines, and on ECS that is the part that is optional. **An
ECS cluster is a name that tasks and services belong to, plus whatever capacity you have given it
to run them on.** Created on its own, it has no capacity at all:

```
ana@laptop:~/aws$ aws ecs create-cluster --cluster-name shop --query "cluster.[clusterName,status,registeredContainerInstancesCount]" --output text
shop	ACTIVE	0
ana@laptop:~/aws$ AMI=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-ecs-hvm-*-x86_64" --query "sort_by(Images,&Name)[-1].ImageId" --output text)
ana@laptop:~/aws$ aws ec2 describe-images --image-ids "$AMI" --query "Images[0].Name" --output text
al2023-ami-ecs-hvm-2023.0.20260226-kernel-6.1-x86_64
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id "$AMI" --instance-type m7i.large --user-data "#!/bin/bash
echo ECS_CLUSTER=shop >> /etc/ecs/ecs.config" --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ecs register-container-instance --cluster shop --instance-identity-document "{\"instanceId\":\"$ID\",\"availabilityZone\":\"sa-east-1a\"}" --query "containerInstance.[ec2InstanceId,status]" --output text
i-963ce1d38adfdbbb0	ACTIVE
ana@laptop:~/aws$ CI=$(aws ecs list-container-instances --cluster shop --query "containerInstanceArns[0]" --output text)
ana@laptop:~/aws$ aws ecs describe-container-instances --cluster shop --container-instances "$CI" --query "containerInstances[0].remainingResources[?name==\`CPU\`||name==\`MEMORY\`].[name,integerValue]" --output text
CPU	4096
MEMORY	7482
```

The `0` in the first line is the number of registered container instances. The rest of the block
gives it one, and every step is one that happens on AWS.

## EC2 capacity: instances that joined

A **container instance** is an ordinary EC2 instance running the ECS agent, a program that talks
to ECS, starts and stops containers through Docker and reports what the instance has left. AWS
publishes ECS-optimised AMIs with the agent and Docker already installed, and moto's catalogue
carries their names, which is how the block found one.

The instance learns which cluster to join from a single line in `/etc/ecs/ecs.config`, written by
user data at first boot, the mechanism of lesson 7. Without it the agent joins a cluster called
`default`. The instance also needs an instance profile whose role allows the agent to register and
to poll for work; AWS's managed policy for that is `AmazonEC2ContainerServiceforEC2Role`, and
`aws-foundations` lesson 10 is where instance profiles were attached.

**On AWS the agent calls `register-container-instance` itself, the moment it starts.** moto runs
no agent, so the block made that call by hand, with the identity document the agent would have
sent. That is staged; everything after it is what ECS keeps.

The resources it reported are moto's: 4,096 CPU units and 7,482 MiB. An `m7i.large` has 2 vCPUs,
which the agent registers as 2,048 units, and 8 GiB, of which it registers a little less than all,
because the operating system and the agent keep some. **The arithmetic of placement is the same
either way**: a task fits on an instance if what it asks for is less than what is left.

## A port is a resource too

The task definition fixed `hostPort` at 8080. One task took it; a second asked for the same port on
the same instance:

```
ana@laptop:~/aws$ aws ecs run-task --cluster shop --task-definition web --query "{tasks: length(tasks), failures: failures}"
{
    "tasks": 0,
    "failures": []
}
ana@laptop:~/aws$ aws ecs describe-container-instances --cluster shop --container-instances "$CI" --query "containerInstances[0].remainingResources[?name==\`PORTS\`].stringSetValue[]" --output text
22	2376	2375	51678	51679	8080
```

moto placed nothing, returned no failure, and lists 8080 among the instance's reserved ports.
**On AWS the same call answers with a failure whose reason is `RESOURCE:PORTS`**, the scheduler's
way of saying the only instance with room had the port taken. That is the cost of a fixed host
port: one copy per instance, however much CPU and memory are left. Setting `hostPort` to `0`
lets Docker choose a free port for each task, and a load balancer's target group, which ECS keeps
up to date with each task's port, is how traffic still finds them all.

## Capacity providers

Registering instances by hand does not scale, and neither does deciding which tasks go where. A
**capacity provider** is a named source of capacity a cluster can draw on. There are three kinds:
`FARGATE`, `FARGATE_SPOT`, and one you create from an auto scaling group of container instances,
built as lesson 4 builds groups:

```
ana@laptop:~/aws$ ASG=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ecs-web --query "AutoScalingGroups[0].AutoScalingGroupARN" --output text)
ana@laptop:~/aws$ aws ecs create-capacity-provider --name ecs-web --auto-scaling-group-provider "autoScalingGroupArn=$ASG,managedScaling={status=ENABLED,targetCapacity=90},managedTerminationProtection=DISABLED" --query "capacityProvider.[name,status,autoScalingGroupProvider.managedScaling.targetCapacity]" --output text
ecs-web	ACTIVE	90
ana@laptop:~/aws$ aws ecs put-cluster-capacity-providers --cluster shop --capacity-providers ecs-web FARGATE FARGATE_SPOT --default-capacity-provider-strategy capacityProvider=ecs-web,base=1,weight=1 --query "cluster.[capacityProviders,defaultCapacityProviderStrategy]"
[
    [
        "ecs-web",
        "FARGATE",
        "FARGATE_SPOT"
    ],
    [
        {
            "capacityProvider": "ecs-web",
            "weight": 1,
            "base": 1
        }
    ]
]
```

`managedScaling` with a target of 90 hands the group's size to ECS: it grows the group when tasks
are waiting for room and shrinks it when instances sit idle, aiming to keep 90% of the capacity in
use. moto stores the setting and scales nothing.

A **capacity provider strategy** says how a service spreads its tasks over providers. `base`
is how many tasks go to a provider before any weighting, and `weight` divides the rest. The
default strategy above puts every task on the EC2 group, at least one there whatever happens.
A service that set `base=2` on `FARGATE` and weights of 1 on `FARGATE` and 3 on `FARGATE_SPOT`
would put its first 2 tasks on Fargate and then 1 in every 4 after that, the rest on Spot.
Lesson 9 is Fargate, and its section on Fargate Spot returns to the strategy.

## What it costs

ECS itself has no charge. **You pay for the capacity**: on EC2, the instances, whether or not
tasks fill them. From the price sheet of 16 October 2026:

```
ana@laptop:~/aws$ python3 prices.py ec2 | grep -E "m7i.large|m7g.large"
  m7i.large    2 vCPU   8 GiB  EBS only          0.16065  per hour
  m7g.large    2 vCPU   8 GiB  EBS only           0.1301  per hour
```

An `m7i.large` running as a container instance all month is 0.16065 × 730 = 117.27 USD, whether
it holds one quarter-vCPU task or eight. That is the trade the next lesson turns around: Fargate
charges for what each task reserves, and nothing for an instance, because there is none of yours.
