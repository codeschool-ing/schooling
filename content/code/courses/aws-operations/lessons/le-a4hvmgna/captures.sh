#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of aws-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   PYTHON3_DIR=... bash lab.sh student   # once: ~/aws built from "environment"
#   bash captures.sh
#
# The files the lesson shows (build-trust.json, buildspec.yml, pipeline.json...)
# are written here with `put` and quoted from the run, so the lesson's copy and
# the one the commands used are the same bytes.
#
# STAGED: moto's own terminal is a background process whose log is printed
# (block moto-terminal). The request to the real AWS in block no-endpoint was
# made: it is the one call in this course that leaves the laptop, with the
# credentials test/test, which AWS refuses.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -f build-trust.json pipeline-trust.json buildspec.yml build-project.json pipeline.json moto.log

MOTO_LOG=$HOME/aws/moto.log moto_up
# shellcheck disable=SC1090
. <(python3 - "$HERE/environment.md" <<'PY'
import re, sys
print(re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)[3])
PY
)

block check
run 'aws --version'
run 'aws sts get-caller-identity'
run 'du -sh ~/aws/venv ~/.local/aws-cli'

block moto-terminal
sed -n '1,8p' moto.log | sed 's/\x1b\[[0-9;]*m//g'

block no-endpoint
( unset AWS_ENDPOINT_URL; run 'aws sts get-caller-identity' )

block port-taken
run 'timeout 10 moto_server -p 4567 2>&1 | tail -2'

# ---- the price list, read by the lesson's own program ---------------------
from_lesson "$HERE/prices.md" price.py > price.py
block price-pipeline
run 'python3 price.py AWSCodePipeline'
run 'python3 price.py CodeBuild Build-Min:Linux:g1'

# ---- the build project ------------------------------------------------------
block artifacts
run 'aws s3 mb s3://shop-artifacts-123456789012'
run 'aws s3api put-bucket-versioning --bucket shop-artifacts-123456789012 --versioning-configuration Status=Enabled'
put build-trust.json <<'EOF'
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
EOF
block build-role
run 'aws iam create-role --role-name shop-build --assume-role-policy-document file://build-trust.json --query Role.Arn --output text'

put buildspec.yml <<'EOF'
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
EOF
put build-project.json <<'EOF'
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
EOF
block project-codepipeline
run 'aws codebuild create-project --cli-input-json file://build-project.json --query project.name'
block project
quiet 'python3 -c "
import json; p = json.load(open(\"build-project.json\"))
p[\"source\"] = {\"type\": \"S3\", \"location\": \"shop-artifacts-123456789012/source.zip\", \"buildspec\": \"buildspec.yml\"}
p[\"artifacts\"] = {\"type\": \"NO_ARTIFACTS\"}
json.dump(p, open(\"build-project-s3.json\", \"w\"), indent=2)
"'
run 'aws codebuild create-project --cli-input-json file://build-project-s3.json --query project.name'
block build
run 'BUILD=$(aws codebuild start-build --project-name shop-api --query build.id --output text); echo "$BUILD"'
BUILD=$(aws codebuild list-builds-for-project --project-name shop-api --query 'ids[0]' --output text)
sleep 1
run "aws codebuild batch-get-builds --ids $BUILD --query 'builds[0].phases[].[phaseType,phaseStatus,durationInSeconds]' --output text"
run "aws codebuild batch-get-builds --ids $BUILD --query 'builds[0].[buildStatus,startTime,endTime]' --output text"

# ---- the pipeline -----------------------------------------------------------
put pipeline.json <<'EOF'
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
EOF
block pipeline-refused
run 'aws codepipeline create-pipeline --pipeline file://pipeline.json'
put pipeline-trust.json <<'EOF'
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
EOF
block pipeline-made
run 'aws iam create-role --role-name shop-pipeline --assume-role-policy-document file://pipeline-trust.json --query Role.Arn --output text'
run 'sed -i "s|role/shop-build|role/shop-pipeline|" pipeline.json'
run "aws codepipeline create-pipeline --pipeline file://pipeline.json --query 'pipeline.stages[].name' --output text"
run "aws codepipeline get-pipeline --name shop-api --query 'pipeline.stages[].actions[].[name,actionTypeId.provider]' --output text"
block pipeline-start
run 'aws codepipeline start-pipeline-execution --name shop-api 2>&1 | grep -m1 ERROR'

moto_down
block no-moto
run 'aws sts get-caller-identity'
