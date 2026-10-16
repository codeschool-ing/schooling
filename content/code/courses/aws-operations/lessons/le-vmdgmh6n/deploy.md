---
title: Deploying, bootstrapping, and what moto skipped
version: 1
---

`cdk deploy` is the usual way to send the template to AWS, and it needs the account **bootstrapped**
first: `cdk bootstrap` creates a stack called `CDKToolkit` holding a bucket and a repository for the
assets of the previous section, and roles the deployment assumes to upload them and to call
CloudFormation. It also writes the bootstrap's version into a parameter, and that is what the
template's last lines read:

```
ana@laptop:~/aws/cdk$ sed -n '/^Parameters:/,$p' template.yaml
Parameters:
  BootstrapVersion:
    Type: AWS::SSM::Parameter::Value<String>
    Default: /cdk-bootstrap/hnb659fds/version
    Description: Version of the CDK Bootstrap resources in this environment, automatically retrieved from SSM Parameter Store. [cdk:skip]

```

A parameter of type `AWS::SSM::Parameter::Value<String>` takes its value from Parameter Store when
the stack is created, from the name in `Default`. **A template from the CDK asks whether the account
was bootstrapped**, and a stack created where it was not fails on that parameter.

## Against moto

Neither `cdk bootstrap` nor `cdk deploy` was run for this course. Both create the toolkit stack and
upload to its bucket through the CDK's own roles, and moto implements too little of that path. What
the CDK hands to CloudFormation is still an ordinary template, so the lab sends it with the AWS
command line, as lesson 4 did. First without the parameter:

```
ana@laptop:~/aws/cdk$ aws cloudformation create-stack --stack-name ShopBase --template-body file://cdk.out/ShopBase.template.json --query StackId --output text

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
ana@laptop:~/aws/cdk$ aws cloudformation wait stack-create-complete --stack-name ShopBase

aws: [ERROR]: Waiter StackCreateComplete failed: Waiter encountered a terminal failure state: Matched expected service error code: ValidationError
ana@laptop:~/aws/cdk$ aws cloudformation describe-stacks --stack-name ShopBase --query 'Stacks[0].[StackStatus,StackStatusReason]' --output text

aws: [ERROR]: An error occurred (ValidationError) when calling the DescribeStacks operation: Stack with id ShopBase does not exist
```

moto fails with an internal error where AWS would refuse with a message naming the missing
parameter. Then with the parameter put where `cdk bootstrap` would have put it:

```
ana@laptop:~/aws/cdk$ aws ssm put-parameter --name /cdk-bootstrap/hnb659fds/version --type String --value 30 --query Version
1
ana@laptop:~/aws/cdk$ aws cloudformation create-stack --stack-name ShopBase --template-body file://cdk.out/ShopBase.template.json --query StackId --output text
arn:aws:cloudformation:sa-east-1:123456789012:stack/ShopBase/63342bf5-29f0-4a9d-a1a8-902eb97d026e
ana@laptop:~/aws/cdk$ aws cloudformation wait stack-create-complete --stack-name ShopBase
ana@laptop:~/aws/cdk$ aws cloudformation describe-stacks --stack-name ShopBase --query 'Stacks[0].StackStatus' --output text
CREATE_COMPLETE
ana@laptop:~/aws/cdk$ aws cloudformation describe-stack-resources --stack-name ShopBase --query 'StackResources[].[LogicalResourceId,ResourceType]' --output text
Uploads4F6EB0FD	AWS::S3::Bucket
None	None
WebLogs48A7C011	AWS::Logs::LogGroup
Alerts91F83244	AWS::SNS::Topic
None	None
None	None
```

`CREATE_COMPLETE`, and three of the six resources are `None`. **moto created the bucket, the log group
and the topic, and silently skipped the bucket policy, the alarm and the metadata**, while reporting
the stack complete. The policy refusing plain HTTP, the one decision the whole of the previous
section was about, does not exist in the lab.

That is the second time in this course that moto has reported success over something it did not do,
after the build of lesson 1, and it is the reason the next section exists: **a test that reads the
template does not depend on what any service did with it**.

## On a real account

On AWS, the same app would be deployed with two commands, run once and then on every change:

```sh
cdk bootstrap aws://123456789012/sa-east-1
cdk deploy ShopBase
```

`cdk deploy` creates a change set, shows the security-relevant parts of it (new IAM statements, new
security group rules) and asks for confirmation before executing it. `cdk diff` shows the template's
difference from what is deployed, without changing anything. In a pipeline, `cdk synth` runs in the
build and the deployment executes the synthesized template, with a change set and an approval between
them, exactly as lesson 4 described.
