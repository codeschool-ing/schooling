---
title: A build project and its buildspec
version: 1
---

CodeBuild is two things kept apart. The **project** says where a build runs: which container image,
how large a machine, which role, where the source comes from. The **buildspec** says what the build
does, as a file in the repository beside the code, so a change to the build is reviewed in the same
pull request as the change it builds.

## The buildspec

The shop's API is a Python service in a container, and its buildspec, `buildspec.yml`, tests it,
builds the image and writes the artifact the deployment needs:

```yaml
version: 0.2

env:
  variables:
    REPOSITORY: 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/api

phases:
  install:
    runtime-versions:
      python: 3.12
  pre_build:
    commands:
      - python -m pip install -r requirements.txt
      - python -m unittest discover -s tests
  build:
    commands:
      - TAG=$(echo "$CODEBUILD_RESOLVED_SOURCE_VERSION" | cut -c1-12)
      - docker build -t "$REPOSITORY:$TAG" .
  post_build:
    commands:
      - docker push "$REPOSITORY:$TAG"
      - printf '[{"name":"api","imageUri":"%s"}]' "$REPOSITORY:$TAG" > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

A build runs its **phases** in order: `install`, `pre_build`, `build`, `post_build`. Each holds
commands, and every command runs in the same shell, so `TAG` set in `build` is still there in
`post_build`. `runtime-versions` picks a Python from the ones the build image carries. The tag is
the first twelve characters of the commit, which `CODEBUILD_RESOLVED_SOURCE_VERSION` holds, so the
image in the registry says which code it was built from; lesson 2 is about why that matters.
`artifacts` lists what is zipped and passed on, and here that is one small file.

**What happens when a command fails is where builds surprise people**, and it is AWS's documented
behaviour rather than anything run here. A failure in `install` or `pre_build` ends the build:
the later phases are skipped. A failure in `build` does **not** skip `post_build`, which still runs,
with the variable `CODEBUILD_BUILD_SUCCEEDING` set to `0`. The buildspec above therefore pushes an
image even when the build phase failed, unless `post_build` checks first:

```sh
[ "$CODEBUILD_BUILD_SUCCEEDING" = 1 ] || exit 1
```

That line at the top of `post_build` is the difference between a failed build and a failed build
that published something.

## The project

The project is registered once. The artifacts need a bucket that keeps versions, and the build
needs a role whose trust policy names CodeBuild:

```
ana@laptop:~/aws$ aws s3 mb s3://shop-artifacts-123456789012
make_bucket: shop-artifacts-123456789012
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket shop-artifacts-123456789012 --versioning-configuration Status=Enabled
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "codebuild.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name shop-build --assume-role-policy-document file://build-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-build
```

The project itself is a file too, so it can be reviewed and kept:

```json
{
  "name": "shop-api",
  "source": { "type": "CODEPIPELINE", "buildspec": "buildspec.yml" },
  "artifacts": { "type": "CODEPIPELINE" },
  "environment": {
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/standard:7.0",
    "computeType": "BUILD_GENERAL1_SMALL",
    "privilegedMode": true
  },
  "serviceRole": "arn:aws:iam::123456789012:role/shop-build"
}
```

`privilegedMode` is what lets the build run `docker build` inside its own container. The source of
type `CODEPIPELINE` means the pipeline hands the build its source. **moto refuses that one**, where
AWS accepts it:

```
ana@laptop:~/aws$ aws codebuild create-project --cli-input-json file://build-project.json --query project.name

aws: [ERROR]: An error occurred (InvalidInputException) when calling the CreateProject operation: Project source location is required
```

So in this lab the project takes its source from the bucket instead, which is the same file with
two fields changed, and moto registers it:

```
ana@laptop:~/aws$ aws codebuild create-project --cli-input-json file://build-project-s3.json --query project.name
"shop-api"
```

## A build that ran nothing

Start one, and ask what happened:

```
ana@laptop:~/aws$ BUILD=$(aws codebuild start-build --project-name shop-api --query build.id --output text); echo "$BUILD"
shop-api:49552943-c623-42b8-ac79-a43dc9467c1d
ana@laptop:~/aws$ aws codebuild batch-get-builds --ids shop-api:49552943-c623-42b8-ac79-a43dc9467c1d --query 'builds[0].phases[].[phaseType,phaseStatus,durationInSeconds]' --output text
SUBMITTED	SUCCEEDED	0
QUEUED	SUCCEEDED	None
PROVISIONING	SUCCEEDED	49
DOWNLOAD_SOURCE	SUCCEEDED	23
INSTALL	SUCCEEDED	37
PRE_BUILD	SUCCEEDED	10
BUILD	SUCCEEDED	20
POST_BUILD	SUCCEEDED	55
UPLOAD_ARTIFACTS	SUCCEEDED	19
FINALIZING	SUCCEEDED	69
COMPLETED	SUCCEEDED	100
ana@laptop:~/aws$ aws codebuild batch-get-builds --ids shop-api:49552943-c623-42b8-ac79-a43dc9467c1d --query 'builds[0].[buildStatus,startTime,endTime]' --output text
SUCCEEDED	2026-10-16T15:22:16.102000+00:00	2026-10-16T15:26:16.102000+00:00
```

Every phase succeeded. The phases add up to 382 seconds, and the build ended four minutes after it
started, so the numbers do not even agree with each other. **None of it happened.** There is no `source.zip` in the bucket, no `tests`
directory and no Docker anywhere: moto marks a build successful and invents the durations, and a
second run prints different numbers. It is the clearest instance of what the section on moto said.
The commands in the buildspec are ordinary shell commands, so the way to know they work is to run
them in your own terminal, in the project's directory, before a pipeline ever does.
