#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# cfn-lint is installed by the first sh fence of the section "anatomy", read
# from the lesson; the template is written here with `put` and quoted from the
# run. The change to the log group's retention in block drift-by-hand stands
# for "somebody changed it in the console", which this lab has no console for.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf cfn && mkdir cfn && cd cfn || exit 1
fence "$HERE/anatomy.md" 1
moto_up
student_env

put shop.yaml <<'EOF2'
AWSTemplateFormatVersion: "2010-09-09"
Description: The shop's logs, uploads and alerts.

Parameters:
  Retention:
    Type: Number
    Default: 15
    Description: Days the web logs are kept.

Resources:
  WebLogs:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: /shop/web
      RetentionInDays: !Ref Retention

  Uploads:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
    Properties:
      BucketName: shop-uploads-123456789012
      VersioningConfiguration:
        Status: Enabled

  Alerts:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Ref AlertTopicName

Outputs:
  UploadsArn:
    Value: !GetAtt Uploads.Arn
  AlertsArn:
    Value: !Ref Alerts
EOF2
block lint-first
run 'cfn-lint shop.yaml; echo "exit status $?"'

# the three fixes the lesson describes, made to the same file
python3 - <<'PY'
s = open('shop.yaml').read()
s = s.replace('    Type: Number\n    Default: 15\n', '    Type: Number\n    Default: 14\n    AllowedValues: [7, 14, 30, 90]\n')
s = s.replace('    DeletionPolicy: Retain\n', '    DeletionPolicy: Retain\n    UpdateReplacePolicy: Retain\n')
s = s.replace('      TopicName: !Ref AlertTopicName\n', '      TopicName: shop-alerts\n')
open('shop.fixed', 'w').write(s)
PY
put shop.yaml < shop.fixed
block lint-clean
run 'cfn-lint shop.yaml; echo "exit status $?"'

block create
run 'aws cloudformation create-stack --stack-name shop-base --template-body file://shop.yaml --query StackId --output text'
run 'aws cloudformation wait stack-create-complete --stack-name shop-base'
run "aws cloudformation describe-stack-resources --stack-name shop-base --query 'StackResources[].[LogicalResourceId,ResourceType,PhysicalResourceId]' --output text"
run "aws cloudformation describe-stacks --stack-name shop-base --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' --output text"

block changeset
run 'aws cloudformation create-change-set --stack-name shop-base --change-set-name retention-30 --template-body file://shop.yaml --parameters ParameterKey=Retention,ParameterValue=30 --query Id --output text'
run 'aws cloudformation wait change-set-create-complete --stack-name shop-base --change-set-name retention-30'
run "aws cloudformation describe-change-set --stack-name shop-base --change-set-name retention-30 --query 'Changes[].ResourceChange.[Action,LogicalResourceId,Replacement]' --output text"
quiet 'aws cloudformation delete-change-set --stack-name shop-base --change-set-name retention-30'

block drift-by-hand
run 'aws logs put-retention-policy --log-group-name /shop/web --retention-in-days 1'
block drift-moto
run 'aws cloudformation detect-stack-drift --stack-name shop-base 2>&1 | grep -m1 ERROR'
block drift-compare
run "aws cloudformation describe-stacks --stack-name shop-base --query 'Stacks[0].Parameters[?ParameterKey==\`Retention\`].ParameterValue' --output text"
run "aws logs describe-log-groups --log-group-name-prefix /shop/web --query 'logGroups[0].retentionInDays'"

block delete
run 'aws cloudformation delete-stack --stack-name shop-base'
run 'aws cloudformation wait stack-delete-complete --stack-name shop-base'
run 'aws logs describe-log-groups --log-group-name-prefix /shop/ --query logGroups'
run 'aws s3 ls'
