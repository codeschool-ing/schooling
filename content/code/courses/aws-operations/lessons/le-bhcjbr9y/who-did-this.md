---
title: Answering "who did this?"
version: 1
---

On the morning of 16 October the old exports bucket is gone, and the database's security group has lost
a rule. The question is not whom to blame; lesson 13's review is blameless. It is **what happened**, and
the name in the record is the person to ask what they knew at the time.

## Event history, which moto does not have

On AWS the first place to look is the event history, by one attribute:

```
ana@laptop:~/aws/trail$ aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteBucket 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the LookupEvents operation (reached max retries: 2): <!doctype html>
```

moto answers 500. On AWS this returns the `DeleteBucket` events of the last ninety days, newest first,
with the record of each in `CloudTrailEvent`. One attribute at a time is its limit: *every change bruno
made that afternoon* is not one question for it.

## The trail's files

The trail's bucket holds the files, and a day of them is what the lab needs. moto delivers none, so
`mk-trail.py` makes up a day of the shop in the same layout, a folder per account, region and date, a
gzipped JSON file per delivery, with thirty routine reads by the pipeline and four things people did:

```python
# mk-trail.py: one made-up day of the shop's CloudTrail, in the layout a trail delivers
import datetime as dt
import gzip
import json
import os
import random

ACCOUNT, REGION = "123456789012", "sa-east-1"
rand = random.Random(20)


def who(role, session):
    return {
        "type": "AssumedRole",
        "arn": f"arn:aws:sts::{ACCOUNT}:assumed-role/{role}/{session}",
        "accountId": ACCOUNT,
        "sessionContext": {"sessionIssuer": {"type": "Role", "userName": role,
                                             "arn": f"arn:aws:iam::{ACCOUNT}:role/{role}"}},
    }


def record(at, identity, source, name, ip, agent, params, error=None):
    r = {"eventVersion": "1.11", "eventTime": at.strftime("%Y-%m-%dT%H:%M:%SZ"),
         "eventSource": source, "eventName": name, "awsRegion": REGION,
         "sourceIPAddress": ip, "userAgent": agent, "userIdentity": identity,
         "requestParameters": params, "eventType": "AwsApiCall",
         "readOnly": name.startswith(("Describe", "Get", "List"))}
    if error:
        r["errorCode"], r["errorMessage"] = error
    return r


start = dt.datetime(2026, 10, 15, tzinfo=dt.timezone.utc)
deploy, ana, bruno = who("shop-deploy", "pipeline"), who("shop-admin", "ana"), who("shop-admin", "bruno")
records = []
for minute in sorted(rand.sample(range(24 * 60), 30)):  # the pipeline's routine reads
    at = start + dt.timedelta(minutes=minute)
    records.append(record(at, deploy, "ecs.amazonaws.com", "DescribeServices", "codepipeline.amazonaws.com",
                          "codepipeline.amazonaws.com", {"cluster": "shop", "services": ["api"]}))
the_day = [
    (9, 12, ana, "s3.amazonaws.com", "ListBuckets", "203.0.113.24", {}, None),
    (14, 3, bruno, "ec2.amazonaws.com", "RevokeSecurityGroupIngress", "198.51.100.77",
     {"groupId": "sg-0shopdb", "ipPermissions": {"items": [{"fromPort": 5432, "toPort": 5432}]}}, None),
    (14, 5, bruno, "s3.amazonaws.com", "DeleteBucket", "198.51.100.77", {"bucketName": "shop-exports-old"}, None),
    (16, 40, ana, "kms.amazonaws.com", "ScheduleKeyDeletion", "203.0.113.24",
     {"keyId": "alias/shop-orders", "pendingWindowInDays": 7},
     ("AccessDenied", "User is not authorized to perform: kms:ScheduleKeyDeletion")),
]
for hour, minute, identity, source, name, ip, params, error in the_day:
    at = start + dt.timedelta(hours=hour, minutes=minute)
    records.append(record(at, identity, source, name, ip, "aws-cli/2.37.4", params, error))

records.sort(key=lambda r: r["eventTime"])
for hour in range(24):  # a trail delivers a file every few minutes; here, one per hour
    batch = [r for r in records if r["eventTime"][11:13] == f"{hour:02d}"]
    if not batch:
        continue
    folder = f"AWSLogs/{ACCOUNT}/CloudTrail/{REGION}/2026/10/15"
    os.makedirs(folder, exist_ok=True)
    name = f"{ACCOUNT}_CloudTrail_{REGION}_20261015T{hour:02d}00Z_lab.json.gz"
    with gzip.open(os.path.join(folder, name), "wt") as f:
        json.dump({"Records": batch}, f)
print(len(records), "records written")
```

The program writes the files locally; copying them into the bucket stands for CloudTrail's delivery, and
from there they are fetched the way a real investigation fetches them:

```
ana@laptop:~/aws/trail$ python3 mk-trail.py
34 records written
ana@laptop:~/aws/trail$ aws s3 cp --recursive --quiet AWSLogs s3://shop-trail-123456789012/AWSLogs
ana@laptop:~/aws/trail$ aws s3 ls s3://shop-trail-123456789012 --recursive | awk 'NR <= 2'
2026-10-16 16:49:05        418 AWSLogs/123456789012/CloudTrail/sa-east-1/2026/10/15/123456789012_CloudTrail_sa-east-1_20261015T0000Z_lab.json.gz
2026-10-16 16:49:05        418 AWSLogs/123456789012/CloudTrail/sa-east-1/2026/10/15/123456789012_CloudTrail_sa-east-1_20261015T0200Z_lab.json.gz
ana@laptop:~/aws/trail$ rm -r AWSLogs && aws s3 sync --quiet s3://shop-trail-123456789012/AWSLogs AWSLogs && find AWSLogs -name "*.json.gz" | wc -l
18
```

## Four questions, one command each

Every query is the same pipe: `find` the files, `zcat` them into one stream, and let `jq` choose. **Who
deleted the bucket?**

```
ana@laptop:~/aws/trail$ find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -c '.Records[] | select(.eventName == "DeleteBucket") | [.eventTime, .userIdentity.arn, .sourceIPAddress, .requestParameters.bucketName]'
["2026-10-15T14:05:00Z","arn:aws:sts::123456789012:assumed-role/shop-admin/bruno","198.51.100.77","shop-exports-old"]
```

Bruno, through the `shop-admin` role, from 198.51.100.77, at 14:05 UTC. **What did people change that
day?** The reads are excluded with `readOnly`, which leaves only the changes, each with the role, the
session name and whether it worked:

```
ana@laptop:~/aws/trail$ find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -r '.Records[] | select(.readOnly == false) | [.eventTime, .userIdentity.sessionContext.sessionIssuer.userName, (.userIdentity.arn | split("/")[-1]), .eventName, .errorCode // "-"] | @tsv' | sort
2026-10-15T14:03:00Z	shop-admin	bruno	RevokeSecurityGroupIngress	-
2026-10-15T14:05:00Z	shop-admin	bruno	DeleteBucket	-
2026-10-15T16:40:00Z	shop-admin	ana	ScheduleKeyDeletion	AccessDenied
```

Two minutes before the bucket, the same session revoked the rule for port 5432 on the database's
security group: the two changes the morning noticed, by one person in one session, which is a
conversation rather than an investigation. The third line failed, and **a failure is worth reading**:

```
ana@laptop:~/aws/trail$ find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -r '.Records[] | select(.errorCode) | .errorMessage'
User is not authorized to perform: kms:ScheduleKeyDeletion
```

Ana tried to schedule the deletion of the orders key and was refused, which is the key policy of lesson
18 doing its work, and a good question for the next handoff. **Who was busy?**

```
ana@laptop:~/aws/trail$ find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -r '.Records[] | .userIdentity.arn' | sort | uniq -c
      2 arn:aws:sts::123456789012:assumed-role/shop-admin/ana
      2 arn:aws:sts::123456789012:assumed-role/shop-admin/bruno
     30 arn:aws:sts::123456789012:assumed-role/shop-deploy/pipeline
```

Thirty calls from the pipeline and four from people. On a real account the same command, over a month,
is how a team finds the role nobody remembers that still makes calls every hour.

On AWS the same queries run without downloading anything, in **CloudTrail Lake**, which keeps events in
its own store and answers SQL, or in Athena over the bucket; both cost per gigabyte scanned. For a
question asked once, `jq` over a day's files is enough.
