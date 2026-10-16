---
title: The recorder, and the history of every resource
version: 1
---

CloudTrail, lesson 20, records **what was asked**. AWS Config records **what things are**: for every
resource it supports, a **configuration item**, a snapshot of the resource's settings, its tags and its
relationships, written each time the resource changes. Put in order, the items are the resource's
history, and the question they answer is the one CloudTrail cannot: *what did this bucket look like last
Tuesday, before somebody changed it?*

Config is off until a **recorder** is created and started, with a **delivery channel** naming the bucket
the snapshots and history files go to. Work in `~/aws/config` (`mkdir -p ~/aws/config && cd ~/aws/config`):

```
ana@laptop:~/aws/config$ aws s3 mb s3://shop-config-123456789012
make_bucket: shop-config-123456789012
ana@laptop:~/aws/config$ aws configservice put-configuration-recorder --configuration-recorder name=default,roleARN=arn:aws:iam::123456789012:role/config-recorder --recording-group allSupported=true,includeGlobalResourceTypes=false
ana@laptop:~/aws/config$ aws configservice put-delivery-channel --delivery-channel name=default,s3BucketName=shop-config-123456789012
ana@laptop:~/aws/config$ aws configservice start-configuration-recorder --configuration-recorder-name default
ana@laptop:~/aws/config$ aws configservice describe-configuration-recorder-status --query 'ConfigurationRecordersStatus[0].[name,recording,lastStatus]' --output text
default	True	PENDING
```

`allSupported=true` records every resource type Config supports in the region; `includeGlobalResourceTypes`
leaves IAM out, which is recorded once, in one region, rather than in every one. On AWS the role must
exist and allow Config to read the account and write to the bucket; moto checks neither, and reports the
recorder's status as `PENDING` for ever, where AWS would report `SUCCESS` after the first delivery.

## What it sees

Three more buckets, the shop's, each in a different state, so that the rules of the next sections have
something to say:

```sh
for b in shop-exports shop-orders tmp-test-ana; do aws s3 mb s3://$b; done
aws s3api put-bucket-tagging --bucket shop-exports --tagging 'TagSet=[{Key=owner,Value=data}]'
aws s3api put-bucket-tagging --bucket shop-orders --tagging 'TagSet=[{Key=owner,Value=checkout}]'
aws s3api put-bucket-tagging --bucket shop-config-123456789012 --tagging 'TagSet=[{Key=owner,Value=platform}]'
for b in shop-orders shop-config-123456789012; do
  aws s3api put-public-access-block --bucket $b --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
done
```

The inventory and the first item of one bucket's history:

```
ana@laptop:~/aws/config$ aws configservice list-discovered-resources --resource-type AWS::S3::Bucket --query 'resourceIdentifiers[].resourceId' --output text
shop-config-123456789012	shop-exports	shop-orders	tmp-test-ana
ana@laptop:~/aws/config$ aws configservice get-resource-config-history --resource-type AWS::S3::Bucket --resource-id shop-exports --query 'configurationItems[0].[configurationItemStatus,configurationItemCaptureTime]' --output text
ResourceDiscovered	2026-10-16T19:56:07.215182+00:00
ana@laptop:~/aws/config$ aws configservice get-resource-config-history --resource-type AWS::S3::Bucket --resource-id shop-exports --query 'configurationItems[0].[tags, supplementaryConfiguration.PublicAccessBlockConfiguration]'
[
    {
        "owner": "data"
    },
    null
]
```

Four buckets, discovered. `shop-exports` has an item recording its discovery, and the item carries the
tags and, among the **supplementary configuration**, the bucket's public access block, which is absent:
nothing was set on it. Every later change, a tag added, the block turned on, would be a new item with its
own time, and `get-resource-config-history` would list them newest first. Lesson 20 says who changed it;
this says what it was before and after.
