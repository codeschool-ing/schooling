---
title: "awsvpc: every task a member of the subnet"
version: 1
---

Fargate is usually described as "ECS without servers", which is true and hides the part that
changes the most. **On Fargate a task is not placed on an instance you can see.** AWS starts it on
capacity of its own and plugs it into your VPC through a network interface of its own. The
instance, its agent, its AMI and its patches from lesson 8 are gone. What arrives in their place
is a task with an IP address in your subnet.

That networking is the `awsvpc` mode, and it is the only one Fargate accepts. It exists on EC2
too, but on Fargate it is the whole story, so it is the place to start.

## The definition, changed for Fargate

Lesson 8's `web.json`, rewritten for Fargate. Save it as `~/aws/fargate.json`:

```schooling-example
{"language": "json", "file": "fargate.json", "parts": [{"code": "{\n  \"family\": \"web-fargate\",\n  \"taskRoleArn\": \"arn:aws:iam::123456789012:role/web-task\",\n  \"executionRoleArn\": \"arn:aws:iam::123456789012:role/web-execution\",\n", "note": "The same family idea and the same two roles as lesson 8's web.json. On Fargate the execution role is not optional in practice: there is no instance role to fall back on for pulling the image or writing logs."}, {"code": "  \"networkMode\": \"awsvpc\",\n  \"requiresCompatibilities\": [\"FARGATE\"],\n", "note": "`awsvpc` is the only network mode Fargate accepts: the task gets its own network interface in your subnet. `FARGATE` asks ECS to check, at registration, that nothing in the file needs an instance."}, {"code": "  \"cpu\": \"256\",\n  \"memory\": \"512\",\n", "note": "On Fargate the size belongs to the task, and it is what you are billed for: a quarter of a vCPU and 512 MiB, by the second. Only certain pairs are allowed, which the second section lists."}, {"code": "  \"runtimePlatform\": {\n    \"cpuArchitecture\": \"ARM64\",\n    \"operatingSystemFamily\": \"LINUX\"\n  },\n", "note": "Graviton instead of x86, which is cheaper by the hour on the price sheet. The image has to exist for `arm64`; `nginx:1.29-alpine` is published for both."}, {"code": "  \"containerDefinitions\": [\n    {\n      \"name\": \"web\",\n      \"image\": \"nginx:1.29-alpine\",\n      \"essential\": true,\n      \"memory\": 512,\n", "note": "The container's own `memory` is optional on Fargate, and may not exceed the task's. Here it equals it, so the one container has the whole task."}, {"code": "      \"portMappings\": [\n        { \"containerPort\": 80, \"protocol\": \"tcp\" }\n      ],\n", "note": "No `hostPort`. In `awsvpc` the port is opened on the task's own address, so two tasks both on port 80 never collide, and lesson 8's `RESOURCE:PORTS` cannot happen."}, {"code": "      \"stopTimeout\": 30,\n", "note": "Seconds between `SIGTERM` and `SIGKILL` when the task is stopped. Fargate allows up to 120, and section 04 is about why the number matters on Fargate Spot."}, {"code": "      \"logConfiguration\": {\n        \"logDriver\": \"awslogs\",\n        \"options\": {\n          \"awslogs-group\": \"/ecs/web\",\n          \"awslogs-region\": \"sa-east-1\",\n          \"awslogs-stream-prefix\": \"web\"\n        }\n      }\n    }\n  ]\n}\n", "note": "Unchanged from lesson 8. With no instance to read a log file on, this is the only place the container's output goes."}]}
```

## One interface per task

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 316\" role=\"img\" aria-label=\"Two ways a task meets the network. On the left, EC2 in bridge mode: one instance with one network interface, address 10.0.1.10 and the instance's security group; two tasks sit behind it on Docker's bridge, reached on host ports 32768 and 32769, sharing the instance's address and security group. On the right, Fargate in awsvpc mode: in the subnet, each task has its own network interface, with its own address, 10.0.1.21 and 10.0.1.22, port 80 on each, and the security group sg-web-task; no instance of yours exists.\"><rect x=\"12\" y=\"12\" width=\"342\" height=\"292\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">EC2, bridge mode</text><rect x=\"28\" y=\"48\" width=\"310\" height=\"240\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">an instance you run</text><rect x=\"42\" y=\"80\" width=\"282\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"183\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one network interface</text><text x=\"183\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.0.1.10  sg-instance</text><rect x=\"42\" y=\"130\" width=\"282\" height=\"144\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"56\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Docker's bridge</text><rect x=\"56\" y=\"160\" width=\"120\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"116\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">task</text><text x=\"116\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">:32768 → :80</text><text x=\"116\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the instance's address</text><text x=\"116\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and its security group</text><rect x=\"192\" y=\"160\" width=\"120\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"252\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">task</text><text x=\"252\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">:32769 → :80</text><text x=\"252\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the instance's address</text><text x=\"252\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and its security group</text><rect x=\"366\" y=\"12\" width=\"342\" height=\"292\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"380\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Fargate, awsvpc mode</text><rect x=\"382\" y=\"48\" width=\"310\" height=\"240\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"396\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">your subnet</text><rect x=\"396\" y=\"86\" width=\"136\" height=\"178\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"464\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">task</text><rect x=\"406\" y=\"122\" width=\"116\" height=\"52\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"464\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">its own interface</text><text x=\"464\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.0.1.21 :80</text><text x=\"464\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sg-web-task</text><text x=\"464\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own address</text><text x=\"464\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and security group</text><text x=\"464\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">host: AWS's</text><rect x=\"542\" y=\"86\" width=\"136\" height=\"178\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">task</text><rect x=\"552\" y=\"122\" width=\"116\" height=\"52\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">its own interface</text><text x=\"610\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.0.1.22 :80</text><text x=\"610\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sg-web-task</text><text x=\"610\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own address</text><text x=\"610\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and security group</text><text x=\"610\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">host: AWS's</text><text x=\"537\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">no instance of yours to see or patch</text></svg>", "caption": "Where the security group sits. In bridge mode tasks hide behind their instance and share its address and its rules, each on a port Docker picked. In awsvpc mode each task is a member of the subnet in its own right, with an address and a security group of its own."}
```

**In `awsvpc` mode the security group belongs to the task.** The rule "the web tasks accept port
80 from inside the VPC" is written once, on a group the tasks carry, and a task of some other
service on the same capacity is not covered by it. In bridge mode the instance's group had to
allow whatever any of its tasks needed, so the loosest task set the rules for all of them.

It also costs addresses. Every task takes one private IP from the subnet, so a `/24` subnet,
with 251 usable addresses once AWS has reserved five, holds at most 251 tasks and nothing else.
`aws-foundations` lesson 16 sized subnets; for Fargate, size them for tasks, not for instances.

## The network, the definition and a task

The task needs a subnet and a security group, built as `aws-foundations` lessons 16 and 18
built them:

```
ana@laptop:~/aws$ VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ SUBNET=$(aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ SG=$(aws ec2 create-security-group --group-name web-task --description "web tasks" --vpc-id "$VPC" --query GroupId --output text)
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 80 --cidr 10.0.0.0/16 --query Return
true
ana@laptop:~/aws$ aws ecs create-cluster --cluster-name shop --query cluster.status --output text
ACTIVE
```

```
ana@laptop:~/aws$ aws ecs register-task-definition --cli-input-json file://fargate.json --query "taskDefinition.[revision,networkMode,cpu,memory,runtimePlatform.cpuArchitecture]" --output text
1	awsvpc	256	512	ARM64
ana@laptop:~/aws$ aws ecs describe-task-definition --task-definition web-fargate --query "taskDefinition.[requiresCompatibilities,compatibilities]" --output text
FARGATE
EC2	FARGATE
```

The definition asked for `FARGATE`, and ECS answered that it is compatible with both EC2 and
Fargate, which is what `compatibilities` means: `awsvpc` and a task-level size run on either.
Running one:

```
ana@laptop:~/aws$ AWS_MAX_ATTEMPTS=1 aws ecs run-task --cluster shop --task-definition web-fargate --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=DISABLED}" 2>&1 | head -2 | cut -c1-90

aws: [ERROR]: An error occurred (500) when calling the RunTask operation (reached max retr
ana@laptop:~/aws$ aws ec2 describe-network-interfaces --filters "Name=subnet-id,Values=$SUBNET" --query "NetworkInterfaces[].[NetworkInterfaceId,PrivateIpAddress,Groups[0].GroupId,Description]" --output text
eni-5a1e9dfa15a5650f0	10.4.25.151	sg-618d62acc16d5a7eb	moto ECS
```

**The error is moto's, not AWS's.** moto 5.2.3 creates the task's network interface and then
fails, inside its own code, on a field that interface does not carry. `AWS_MAX_ATTEMPTS=1` stops
the CLI from retrying the call, which would otherwise leave three interfaces behind. What did
happen is the part worth seeing: one network interface in the subnet, with an address of its own
and the task's security group. On AWS the call returns the task, `PROVISIONING` and then
`PENDING` while Fargate finds capacity and pulls the image, and `RUNNING` once its containers
start; the interface is listed with the task's attachments and deleted when the task stops.

A task in `awsvpc` mode cannot be started without saying where it goes:

```
ana@laptop:~/aws$ aws ecs run-task --cluster shop --task-definition web-fargate --launch-type FARGATE

aws: [ERROR]: An error occurred (InvalidParameterException) when calling the RunTask operation: Network Configuration must be provided when networkMode 'awsvpc' is specified.
```

That refusal is the same on AWS. A service carries the same configuration and passes it to every
task it starts; moto records it and, as in lesson 8, starts none:

```
ana@laptop:~/aws$ aws ecs create-service --cluster shop --service-name web --task-definition web-fargate --desired-count 2 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=DISABLED}" --query "service.[launchType,desiredCount,runningCount]" --output text
FARGATE	2	0
```

## The trap of the private subnet

`assignPublicIp=DISABLED` is the right setting for a web task behind a load balancer, and the one
that catches people on their first Fargate task. **To start, the task has to pull its image and
reach CloudWatch Logs, and in a private subnet with no route out it can do neither.** It stops
with `CannotPullContainerError`, and the stopped reason says that it could not reach the
registry. Either the subnet routes to a NAT gateway, as `aws-foundations` lesson 17 built, or
the VPC has interface endpoints for ECR and CloudWatch Logs and a gateway endpoint for S3, where
ECR keeps the image layers, which is `aws-foundations` lesson 19. moto pulls nothing, so this
failure never appears here; on AWS it is the first one to expect.
