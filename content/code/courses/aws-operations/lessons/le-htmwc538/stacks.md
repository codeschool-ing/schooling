---
title: A stack, what it owns, and what it leaves behind
version: 1
---

A **stack** is CloudFormation's record of one template applied: which resources it created, under
which physical ids, with which parameters, and every event on the way. Create the shop's base:

```
ana@laptop:~/aws/cfn$ aws cloudformation create-stack --stack-name shop-base --template-body file://shop.yaml --query StackId --output text
arn:aws:cloudformation:sa-east-1:123456789012:stack/shop-base/5eddddae-9d49-4a3a-a355-211cbbf3188d
ana@laptop:~/aws/cfn$ aws cloudformation wait stack-create-complete --stack-name shop-base
ana@laptop:~/aws/cfn$ aws cloudformation describe-stack-resources --stack-name shop-base --query 'StackResources[].[LogicalResourceId,ResourceType,PhysicalResourceId]' --output text
WebLogs	AWS::Logs::LogGroup	/shop/web
Uploads	AWS::S3::Bucket	shop-uploads-123456789012
Alerts	AWS::SNS::Topic	arn:aws:sns:sa-east-1:123456789012:shop-alerts
ana@laptop:~/aws/cfn$ aws cloudformation describe-stacks --stack-name shop-base --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' --output text
UploadsArn	arn:aws:s3:::shop-uploads-123456789012
AlertsArn	arn:aws:sns:sa-east-1:123456789012:shop-alerts
```

The third command is the useful one. `describe-stack-resources` is the link between the template's
names and the cloud's: `WebLogs` is the log group `/shop/web`, `Alerts` is a topic whose physical id
is its ARN. **Everything else that touches these resources should go through the stack**, because the
stack is the only place that knows they belong together.

## When a creation fails

On AWS, a resource that fails during creation makes the whole stack **roll back**: CloudFormation
deletes what it had made, in reverse order, and the stack ends in `ROLLBACK_COMPLETE`. A stack in that
state cannot be updated, only deleted and created again. The events, `describe-stack-events`, carry
the reason on the first resource that failed, and that line is what to read; the dozen
`CREATE_CANCELLED` and `DELETE_COMPLETE` lines after it are consequences.

`--disable-rollback`, or `--on-failure DO_NOTHING`, leaves what was made in place so it can be
inspected, and is worth knowing for a template under development. moto never fails a creation for
the reasons AWS does, so neither path was run here.

## Deleting a stack, and what it keeps

```
ana@laptop:~/aws/cfn$ aws cloudformation delete-stack --stack-name shop-base
ana@laptop:~/aws/cfn$ aws cloudformation wait stack-delete-complete --stack-name shop-base
ana@laptop:~/aws/cfn$ aws logs describe-log-groups --log-group-name-prefix /shop/ --query logGroups
[]
ana@laptop:~/aws/cfn$ aws s3 ls
2026-10-16 12:46:21 shop-uploads-123456789012
```

The stack is gone, and so is the log group it created. The bucket `shop-uploads-123456789012` is still
there, because its `DeletionPolicy` is `Retain`. That is the policy for anything holding data the
stack does not own in spirit: **a bucket of customers' uploads must not disappear because somebody
cleaned up a stack**. The bucket now belongs to no stack, which is also the cost: nothing manages it,
and it is the first kind of resource lesson 24 calls the resource nobody owns.

Two more protections, both documented and not run here, because moto fails on the first:

- **termination protection**, `update-termination-protection --enable-termination-protection`,
  makes `delete-stack` refuse until it is turned off;
- **a stack policy** names resources that an update may not replace or delete, so a change that would
  replace the database fails instead of doing it.
