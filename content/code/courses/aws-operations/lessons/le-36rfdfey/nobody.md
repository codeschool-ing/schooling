---
title: The resource nobody owns
version: 1
---

Six resources of four services, in `~/aws/owners` (`mkdir -p ~/aws/owners && cd ~/aws/owners`), some made
the way the rules say and some made in a hurry:

```sh
aws s3 mb s3://shop-orders
aws s3api put-bucket-tagging --bucket shop-orders --tagging 'TagSet=[{Key=owner,Value=checkout},{Key=environment,Value=prod}]'
aws s3 mb s3://tmp-test-ana
aws logs create-log-group --log-group-name /shop/api --tags owner=api,environment=prod
aws logs create-log-group --log-group-name /shop/old-batch
aws sqs create-queue --queue-name orders --tags owner=checkout
aws dynamodb create-table --table-name carts --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH --billing-mode PAY_PER_REQUEST
```

The **Resource Groups Tagging API** answers *which resources have this tag* across services in one call,
which makes it the obvious tool for finding owners. It has a blind spot, and `owners.py` is written around
it: it lists every resource of the four services from each service's own API, and asks the tagging API
about each one.

```python
# owners.py: every resource of four services, and which of them has no owner
import boto3

region = "sa-east-1"
account = boto3.client("sts").get_caller_identity()["Account"]

tags = {}
for page in boto3.client("resourcegroupstaggingapi").get_paginator("get_resources").paginate():
    for m in page["ResourceTagMappingList"]:
        tags[m["ResourceARN"]] = {t["Key"]: t["Value"] for t in m["Tags"]}

sqs = boto3.client("sqs")
arns = [f"arn:aws:s3:::{b['Name']}" for b in boto3.client("s3").list_buckets()["Buckets"]]
arns += [f"arn:aws:dynamodb:{region}:{account}:table/{t}"
         for t in boto3.client("dynamodb").list_tables()["TableNames"]]
arns += [sqs.get_queue_attributes(QueueUrl=u, AttributeNames=["QueueArn"])["Attributes"]["QueueArn"]
         for u in sqs.list_queues().get("QueueUrls", [])]
arns += [g["arn"].removesuffix(":*") for g in boto3.client("logs").describe_log_groups()["logGroups"]]

for arn in sorted(arns):
    known = arn in tags
    owner = tags.get(arn, {}).get("owner", "-")
    print(f"{owner:<10} {'' if known else 'not in the tagging API':<23} {arn}".rstrip())
```

```
ana@laptop:~/aws/owners$ python3 owners.py
-          not in the tagging API  arn:aws:dynamodb:sa-east-1:123456789012:table/carts
api                                arn:aws:logs:sa-east-1:123456789012:log-group:/shop/api
-          not in the tagging API  arn:aws:logs:sa-east-1:123456789012:log-group:/shop/old-batch
checkout                           arn:aws:s3:::shop-orders
-          not in the tagging API  arn:aws:s3:::tmp-test-ana
checkout                           arn:aws:sqs:sa-east-1:123456789012:orders
```

Three resources have no owner, and all three are also **not in the tagging API at all**:

```
ana@laptop:~/aws/owners$ aws resourcegroupstaggingapi get-resources --query 'ResourceTagMappingList[].ResourceARN' --output text | tr '\t' '\n'
arn:aws:s3:::shop-orders
arn:aws:logs:sa-east-1:123456789012:log-group:/shop/api
arn:aws:sqs:sa-east-1:123456789012:orders
```

**The tagging API returns resources that have tags, or once had them.** A resource that was never tagged
is not untagged in its answer; it is absent. A report built only on it, *resources without an owner tag*,
lists nothing for exactly the resources it exists to find. That is why `owners.py` starts from each
service's inventory, and why on a real account the better inventory is AWS Config's, lesson 21, which
records every supported resource whether or not it has a tag.

## Giving it an owner

Somebody has to decide who owns `carts`: the checkout team, it turns out. The tagging API can tag
resources of any service in one call:

```
ana@laptop:~/aws/owners$ aws resourcegroupstaggingapi tag-resources --resource-arn-list arn:aws:dynamodb:sa-east-1:123456789012:table/carts --tags owner=checkout,environment=prod --query FailedResourcesMap
ana@laptop:~/aws/owners$ python3 owners.py | grep carts
checkout                           arn:aws:dynamodb:sa-east-1:123456789012:table/carts
```

The other two, `tmp-test-ana` and `/shop/old-batch`, are the usual pair: a test somebody forgot, and the
remains of something retired. They are not tagged; they are asked about, and after lesson 23's week of
silence, deleted.
