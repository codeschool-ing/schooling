---
title: A template, and the linter that reads it first
version: 1
---

`iac` lesson 17 showed CloudFormation beside Terraform: a template sent to AWS, a **stack** that
remembers what it made, no state file to protect. This lesson is about running it in production,
where the questions are what a change will do before it does it, and what changed without anybody
saying so. It starts with the file.

## The four parts that matter

A template is YAML (or JSON) with up to nine top-level sections, and four carry nearly everything:

| section | what it holds |
|---|---|
| `Parameters` | values chosen when the stack is created or updated, with a type and limits |
| `Resources` | the only required one: each resource under a **logical id**, with a `Type` and `Properties` |
| `Outputs` | values the stack publishes: an ARN, a URL, for people and for other stacks |
| `Conditions` | true or false, from parameters, deciding whether a resource is created |

Inside them, **intrinsic functions** connect the pieces. `!Ref` gives a parameter's value or a
resource's main identifier; `!GetAtt Uploads.Arn` gives one attribute of a resource; `!Sub` builds a
string with `${...}` placeholders. A reference also orders creation: what is referred to is made
first.

## The linter

CloudFormation reads a template only when it is sent, and a mistake found then is a stack that
failed and rolled back. **cfn-lint**, AWS's own open-source linter, reads it on your laptop first,
against the published specification of every resource type. It goes into the same virtual
environment as moto:

```sh
~/aws/venv/bin/pip install -q 'cfn-lint==1.57.1'
```

The shop's base stack holds the web logs, the uploads bucket and the topic alerts go to. The first
draft:

```yaml
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
```

```
ana@laptop:~/aws/cfn$ cfn-lint shop.yaml; echo "exit status $?"
W1030 {'Ref': 'Retention'} is not one of [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653] when 'Ref' is resolved at 'Resources/WebLogs/Properties/RetentionInDays'
shop.yaml:7:5

W3011 Both 'UpdateReplacePolicy' and 'DeletionPolicy' are needed to protect resource from deletion
shop.yaml:17:3

E1020 'AlertTopicName' is not one of ['Retention', 'WebLogs', 'Uploads', 'Alerts', 'AWS::AccountId', 'AWS::NoValue', 'AWS::NotificationARNs', 'AWS::Partition', 'AWS::Region', 'AWS::StackId', 'AWS::StackName', 'AWS::URLSuffix']
shop.yaml:28:7

exit status 6
```

Three findings, each with the line it is on:

- **W1030**: a log group keeps logs for one of a fixed list of periods, and the parameter's default,
  15, is not one of them. It is a warning only because the value arrives through a parameter, which
  could be given another value; with the default, AWS would refuse the log group at creation, after
  everything before it was made.
- **W3011**: `DeletionPolicy: Retain` keeps the bucket when the stack is deleted, but not when an
  update replaces it; that needs `UpdateReplacePolicy` as well. The template is valid and the data
  is not safe.
- **E1020**: `!Ref AlertTopicName` refers to nothing. The linter lists what it could refer to.

The fixed template sets the default to 14, limits the parameter to values a log group accepts, adds
the second policy and names the topic:

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: The shop's logs, uploads and alerts.

Parameters:
  Retention:
    Type: Number
    Default: 14
    AllowedValues: [7, 14, 30, 90]
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
    UpdateReplacePolicy: Retain
    Properties:
      BucketName: shop-uploads-123456789012
      VersioningConfiguration:
        Status: Enabled

  Alerts:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: shop-alerts

Outputs:
  UploadsArn:
    Value: !GetAtt Uploads.Arn
  AlertsArn:
    Value: !Ref Alerts
```

```
ana@laptop:~/aws/cfn$ cfn-lint shop.yaml; echo "exit status $?"
exit status 0
```

**Exit status 0 and no output** is the result to wire into a pipeline: a buildspec line running
`cfn-lint` before any `deploy` turns these three mistakes into a failed build instead of a failed
stack.
