---
title: The pipeline, and the role that refused it
version: 1
---

A pipeline is a list of **stages**, each a list of **actions**, and it is written down as JSON. The
shop's has four stages: take the source, build it, wait for a person to approve, deploy to ECS.

```json
{
  "name": "shop-api",
  "roleArn": "arn:aws:iam::123456789012:role/shop-build",
  "artifactStore": { "type": "S3", "location": "shop-artifacts-123456789012" },
  "stages": [
    {
      "name": "Source",
      "actions": [{
        "name": "Source",
        "actionTypeId": { "category": "Source", "owner": "AWS", "provider": "S3", "version": "1" },
        "configuration": { "S3Bucket": "shop-artifacts-123456789012", "S3ObjectKey": "source.zip" },
        "outputArtifacts": [{ "name": "src" }]
      }]
    },
    {
      "name": "Build",
      "actions": [{
        "name": "Build",
        "actionTypeId": { "category": "Build", "owner": "AWS", "provider": "CodeBuild", "version": "1" },
        "configuration": { "ProjectName": "shop-api" },
        "inputArtifacts": [{ "name": "src" }],
        "outputArtifacts": [{ "name": "image" }]
      }]
    },
    {
      "name": "Approve",
      "actions": [{
        "name": "Approve",
        "actionTypeId": { "category": "Approval", "owner": "AWS", "provider": "Manual", "version": "1" }
      }]
    },
    {
      "name": "Deploy",
      "actions": [{
        "name": "Deploy",
        "actionTypeId": { "category": "Deploy", "owner": "AWS", "provider": "ECS", "version": "1" },
        "configuration": { "ClusterName": "shop", "ServiceName": "api", "FileName": "imagedefinitions.json" },
        "inputArtifacts": [{ "name": "image" }]
      }]
    }
  ]
}
```

Read it by its artifacts. `Source` writes `src`; `Build` reads `src` and writes `image`, which is the
zip holding `imagedefinitions.json`; `Deploy` reads `image` and tells the ECS service `api` in the
cluster `shop` to run what the file names. `Approve` has no artifacts at all: it is a manual
approval, and the pipeline stops there until somebody with permission presses approve or reject.
A stage runs only when the one before it succeeded, so **a production deployment is three stages of
evidence away from a commit**.

## The first attempt

The file names the build's role as the pipeline's role, which is a slip people make by copying. The
pipeline service checks that it may assume the role before it accepts the pipeline:

```
ana@laptop:~/aws$ aws codepipeline create-pipeline --pipeline file://pipeline.json

aws: [ERROR]: An error occurred (InvalidStructureException) when calling the CreatePipeline operation: CodePipeline is not authorized to perform AssumeRole on role arn:aws:iam::123456789012:role/shop-build
```

That refusal is also what AWS does, and it is the useful kind of refusal: it comes at the moment
the mistake is made, not at three in the morning during the first run. **The role trusts
CodeBuild, so nobody else may wear it**, and the pipeline service is somebody else. It needs a role
of its own, trusted by `codepipeline.amazonaws.com`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "codepipeline.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name shop-pipeline --assume-role-policy-document file://pipeline-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-pipeline
ana@laptop:~/aws$ sed -i "s|role/shop-build|role/shop-pipeline|" pipeline.json
ana@laptop:~/aws$ aws codepipeline create-pipeline --pipeline file://pipeline.json --query 'pipeline.stages[].name' --output text
Source	Build	Approve	Deploy
ana@laptop:~/aws$ aws codepipeline get-pipeline --name shop-api --query 'pipeline.stages[].actions[].[name,actionTypeId.provider]' --output text
Source	S3
Build	CodeBuild
Approve	Manual
Deploy	ECS
```

Four stages, and each action with the provider that does its work. In a real account the
pipeline's role would also need a permission policy granting it the bucket, `codebuild:StartBuild`
and the ECS calls of the deploy action; moto checked the trust and nothing else, which is the
section on moto again.

## Running it, which the lab cannot do

```
ana@laptop:~/aws$ aws codepipeline start-pipeline-execution --name shop-api 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the StartPipelineExecution operation (reached max retries: 2): <!doctype html>
```

moto stores pipelines and does not run them. On AWS a run is an **execution**, with an id, and the
console and `get-pipeline-state` show each stage as it moves through `InProgress` to `Succeeded` or
`Failed`. What is worth knowing about executions, and was not run here:

- **A failed stage stops the execution**, and the stages after it never start. `retry-stage-execution`
  runs the failed actions again with the same artifacts, so a flaky test can be retried without
  rebuilding.
- **By default a newer execution supersedes an older one.** In `SUPERSEDED` mode, a run waiting to
  enter a stage is replaced by a newer run that reaches the same point, so a burst of commits
  produces one deployment of the last of them. V2 pipelines can choose `QUEUED`, where every run
  passes in order, one at a time, or `PARALLEL`, where runs do not wait for each other at all.
- An approval waits up to seven days and then fails, so a run nobody looked at does not reach
  production a week later by itself.
- **Rolling back is a new execution of an older revision**, or, in V2 pipelines, a stage rollback
  to the last successful run. The deployment strategies that make a rollback quick are lesson 3.
