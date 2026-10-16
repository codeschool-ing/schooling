---
title: "Task definitions: a docker run written down"
version: 1
---

People who know Docker tend to arrive at ECS expecting to hand it a container. **ECS never takes a
container; it takes a task definition**, a JSON document that says which images to run, with how
much CPU and memory, on which ports, with which environment and which permissions. Everything ECS
later starts, it starts from one of these. If you have typed a long `docker run` with a dozen
flags, a task definition is that command written down once, given a name and a version, and kept
by AWS.

A **task** is one running copy of a task definition: one or more containers started together, on
the same host, and stopped together. The word to hold on to is that the task, not the container,
is the unit ECS schedules, counts and replaces.

## One definition, part by part

This is the definition for the shop's web front, a single nginx container. Copy it with the button
on the block and save it as `~/aws/web.json`:

```schooling-example
{"language": "json", "file": "web.json", "parts": [{"code": "{\n  \"family\": \"web\",\n", "note": "The family is the name every revision shares. Registering this file again does not overwrite anything: it makes `web:2` beside `web:1`, and a task or a service names the one it runs."}, {"code": "  \"taskRoleArn\": \"arn:aws:iam::123456789012:role/web-task\",\n  \"executionRoleArn\": \"arn:aws:iam::123456789012:role/web-execution\",\n", "note": "Two roles for two different callers. The task role is what the code inside the container may do; the execution role is what ECS itself may do on the task's behalf before the code starts. The next section takes them apart."}, {"code": "  \"networkMode\": \"bridge\",\n  \"requiresCompatibilities\": [\"EC2\"],\n", "note": "`bridge` is Docker's own network on the instance, the one lesson 7's hop limit was about. `EC2` says this definition is meant for instances you run; lesson 9 changes both lines for Fargate."}, {"code": "  \"containerDefinitions\": [\n    {\n      \"name\": \"web\",\n      \"image\": \"nginx:1.29-alpine\",\n      \"essential\": true,\n", "note": "A task can hold several containers; this one holds one. The image is the name `docker pull` would take. `essential` means the task stops when this container stops, which is what you want of the only one."}, {"code": "      \"cpu\": 256,\n      \"memory\": 512,\n", "note": "CPU in units of 1/1024 of a vCPU, so 256 is a quarter; memory in MiB. `memory` here is a hard limit: a container that goes past 512 MiB is killed, not slowed."}, {"code": "      \"portMappings\": [\n        { \"containerPort\": 80, \"hostPort\": 8080, \"protocol\": \"tcp\" }\n      ],\n", "note": "nginx listens on 80 inside the container, and the instance's port 8080 is wired to it. A fixed `hostPort` means one copy of this task per instance, which the third section shows going wrong; `0` would let Docker pick a free port each time."}, {"code": "      \"environment\": [\n        { \"name\": \"SHOP_ENV\", \"value\": \"staging\" }\n      ],\n", "note": "Plain environment variables, readable by anybody who can describe the task definition. A secret goes in `secrets` instead, as a reference to Secrets Manager that the execution role resolves, which is `aws-operations` lesson 17."}, {"code": "      \"logConfiguration\": {\n        \"logDriver\": \"awslogs\",\n        \"options\": {\n          \"awslogs-group\": \"/ecs/web\",\n          \"awslogs-region\": \"sa-east-1\",\n          \"awslogs-stream-prefix\": \"web\"\n        }\n      }\n    }\n  ]\n}\n", "note": "What the container writes to standard output goes to CloudWatch Logs, in the group `/ecs/web`, which has to exist before the first task starts. It is the execution role that is allowed to write there, not the code."}]}
```

Lesson 9 runs the same container on Fargate, and the lines that change there are `networkMode`,
`requiresCompatibilities` and where `cpu` and `memory` sit. The rest of the file is the same,
which is the point of keeping the definition apart from where it runs.

## Two roles, because there are two callers

The two ARNs near the top are where people most often go wrong, usually by giving one role both
jobs. **They answer for different programs at different moments.**

The **execution role** is used by ECS itself, before your code exists. To start the task it has
to pull the image, which from ECR needs `ecr:` permissions, and to send the container's output to
CloudWatch Logs it needs `logs:` ones. Nothing in the container can use this role.

The **task role** is the one the code inside the container receives. When the nginx process, or
an application beside it, calls S3, the SDK finds credentials for this role, much as lesson 7's
CLI found the instance's role. They come from a separate endpoint inside the task rather than
from the instance's metadata service, which is exactly why lesson 7 wanted the hop limit at 1: a
task should get its own role and never borrow the instance's.

Both are ordinary IAM roles whose trust policy names the service that may take them on:

```json
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
```

AWS publishes a managed policy, `AmazonECSTaskExecutionRolePolicy`, with the permissions an
execution role usually needs. moto's copy of AWS's managed policies does not include it, so here
the same six actions go into a policy of the role's own:

```json
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
```

```
ana@laptop:~/aws$ aws iam create-role --role-name web-execution --assume-role-policy-document file://trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/web-execution
ana@laptop:~/aws$ aws iam put-role-policy --role-name web-execution --policy-name pull-and-log --policy-document file://execution.json
ana@laptop:~/aws$ aws iam create-role --role-name web-task --assume-role-policy-document file://trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/web-task
ana@laptop:~/aws$ aws iam attach-role-policy --role-name web-execution --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the AttachRolePolicy operation: Policy arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy does not exist or is not attachable.
```

The last command is the one you would type on AWS, and the refusal is moto's, not AWS's. The task
role gets no policy here: nginx serving a page calls no AWS API. **A task role with nothing
attached is the right default**, and permissions are added one at a time when the code needs them,
as `aws-foundations` lesson 7 put it.

## Registering, and revisions

```
ana@laptop:~/aws$ aws ecs register-task-definition --cli-input-json file://web.json --query "taskDefinition.[taskDefinitionArn,revision,status]"
[
    "arn:aws:ecs:sa-east-1:123456789012:task-definition/web:1",
    1,
    "ACTIVE"
]
ana@laptop:~/aws$ aws ecs register-task-definition --cli-input-json file://web.json --query taskDefinition.taskDefinitionArn --output text
arn:aws:ecs:sa-east-1:123456789012:task-definition/web:2
ana@laptop:~/aws$ aws ecs list-task-definitions --family-prefix web
{
    "taskDefinitionArns": [
        "arn:aws:ecs:sa-east-1:123456789012:task-definition/web:1",
        "arn:aws:ecs:sa-east-1:123456789012:task-definition/web:2"
    ]
}
ana@laptop:~/aws$ aws ecs deregister-task-definition --task-definition web:1 --query taskDefinition.status --output text
INACTIVE
ana@laptop:~/aws$ aws ecs describe-task-definition --task-definition web --query "taskDefinition.[revision,containerDefinitions[0].image]" --output text
2	nginx:1.29-alpine
```

The same file registered twice made two revisions, `web:1` and `web:2`. **A revision never
changes after it is registered**, so a task that says it runs `web:1` means exactly that file,
whatever was registered later. Deregistering marks a revision `INACTIVE`: AWS lets nothing new
start from it, while tasks already running from it carry on. Asking for the family without a
number, as the last command did, gets the latest `ACTIVE` revision.

That is also why a change to the image tag, an environment variable or the memory is never an
edit. It is a new revision, and the next section is about how a service moves from one revision
to the next without stopping the shop.
