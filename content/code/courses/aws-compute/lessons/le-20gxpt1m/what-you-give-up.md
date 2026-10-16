---
title: "What Fargate takes away"
version: 1
---

"No instance to manage" is the selling point, and it is exact: no AMI to patch, no agent to
upgrade, no cluster to keep the right size. **It is also a list of things you can no longer do,
because each of them needed the instance.** Most services never miss any of them. The ones that
do find out at registration, if AWS refuses the definition, or in production, if it does not.

## The list

| on EC2 | on Fargate | why |
|---|---|---|
| SSH into the host | no host to reach; ECS Exec opens a shell inside a container | the host is AWS's |
| `privileged` containers | refused | a privileged container controls the host |
| `bridge` and `host` network modes | `awsvpc` only | there is no host network to share |
| bind mounts from the host's disk | the task's own ephemeral storage, or EFS | no host disk is yours |
| a daemon on every instance | sidecar containers in each task | no instance to run one per |
| GPUs | none | Fargate offers no GPU capacity |
| disk of any size | 20 GB free, up to 200 GB | the task's storage is part of Fargate |

**The daemon row is the one teams trip over.** On EC2 a log shipper or a monitoring agent runs
once per instance, as an ECS service with the `DAEMON` scheduling strategy, and watches every task
on that instance. On Fargate each task is alone on its capacity, so whatever watched it has to
run inside it, as a second container in the same task definition, and is paid for in every task.
The CloudWatch agent and the X-Ray daemon of `aws-operations` lessons 8 and 11 both have a
sidecar form for this reason.

**Storage goes with the task.** The 20 GB a task gets is erased when the task stops, like lesson
3's instance store and for the same reason: it lives on capacity the task gives back. Anything
that must outlive the task goes to a database, to S3, or to an EFS file system mounted into the
task, the one shared disk Fargate supports, also from lesson 3.

**And debugging changes shape.** There is no `docker ps` to run on the host and no log file to
read there. The container's output reaches CloudWatch Logs through the `awslogs` driver, or it
reaches nowhere, and a shell, when one is needed, comes from ECS Exec, which needs the task role
to allow the Systems Manager channel it uses. A task that dies before it logs anything leaves its
stopped reason on the task for about an hour, and that is often the whole of the evidence.

## moto lets all of them through

Three of the rows are refusals on AWS. moto refuses none of them:

```
ana@laptop:~/aws$ aws ecs register-task-definition --family root --network-mode awsvpc --requires-compatibilities FARGATE --cpu 256 --memory 512 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":512,\"privileged\":true}]" --query "taskDefinition.[family,revision]" --output text
root	1
ana@laptop:~/aws$ aws ecs register-task-definition --family bridged --network-mode bridge --requires-compatibilities FARGATE --cpu 256 --memory 512 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":512}]" --query "taskDefinition.[family,networkMode]" --output text
bridged	awsvpc
ana@laptop:~/aws$ aws ecs register-task-definition --family big-disk --network-mode awsvpc --requires-compatibilities FARGATE --cpu 1024 --memory 2048 --ephemeral-storage sizeInGiB=500 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":2048}]" --query "taskDefinition.[family,ephemeralStorage.sizeInGiB]" --output text
big-disk	500
```

A privileged container registered as revision 1. A definition asking for `bridge` came back in
`awsvpc`: moto rewrote the network mode rather than refusing it, which is worse, because a
definition read back from moto says something its author did not write. And 500 GB of ephemeral
storage was accepted where AWS allows 200. **None of these can be found by a run against moto**,
so a Fargate definition is worth reading against the table above before its first registration
on AWS, which is the one that checks.

## The trade, in one sentence each

On EC2 you choose the instance, fill it, patch it, and pay for it full or empty. On Fargate you
choose the task's size, pay for what it reserves, and accept that the machine underneath is not
yours to touch. Lesson 23 weighs the two against Lambda for one workload, with the price sheet in
hand, and lesson 12 comes back to Fargate as capacity for Kubernetes pods.
