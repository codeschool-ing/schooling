---
title: A custom rule, by hand
version: 1
---

When no managed rule says what the team means, a **custom rule** does: a Lambda function that Config
invokes with the configuration item of the resource that changed, which judges it and reports back with
`PutEvaluations`. The shop's rule for buckets combines the two of the previous section in its own words:
**a bucket has an owner, and blocks every kind of public access**.

The lab has no Lambda to invoke, so `evaluate.py` does by hand what such a function does, over the same
inventory: it reads each bucket's latest configuration item from Config, judges it, and reports the
evaluations.

```python
# evaluate.py: what a custom Config rule does, run by hand over Config's own inventory
import datetime as dt
import json

import boto3

config = boto3.client("config")


def verdict(item):
    """The rule: a bucket has an owner tag and blocks every kind of public access."""
    if "owner" not in item.get("tags", {}):
        return "NON_COMPLIANT", "no owner tag"
    block = json.loads(item["supplementaryConfiguration"].get("PublicAccessBlockConfiguration", "{}"))
    if not all(block.get(k) for k in ("blockPublicAcls", "ignorePublicAcls",
                                      "blockPublicPolicy", "restrictPublicBuckets")):
        return "NON_COMPLIANT", "public access not fully blocked"
    return "COMPLIANT", ""


keys = config.list_discovered_resources(resourceType="AWS::S3::Bucket")["resourceIdentifiers"]
items = [config.get_resource_config_history(resourceType=k["resourceType"], resourceId=k["resourceId"],
                                            limit=1)["configurationItems"][0] for k in keys]

evaluations = []
for item in sorted(items, key=lambda i: i["resourceId"]):
    result, why = verdict(item)
    print(f'{item["resourceId"]:<28} {result:<14} {why}'.rstrip())
    evaluations.append({"ComplianceResourceType": item["resourceType"],
                        "ComplianceResourceId": item["resourceId"],
                        "ComplianceType": result, "Annotation": why or "ok",
                        "OrderingTimestamp": dt.datetime.now(dt.timezone.utc)})

# a real custom rule gets ResultToken from the event that invoked it; TestMode records nothing
answer = config.put_evaluations(Evaluations=evaluations, ResultToken="TESTMODE", TestMode=True)
print("rejected by Config:", len(answer["FailedEvaluations"]))
```

```
ana@laptop:~/aws/config$ python3 evaluate.py
shop-config-123456789012     COMPLIANT
shop-exports                 NON_COMPLIANT  public access not fully blocked
shop-orders                  COMPLIANT
tmp-test-ana                 NON_COMPLIANT  no owner tag
rejected by Config: 0
```

Two buckets pass. `shop-exports` has an owner and no public access block, which is the dangerous one:
nothing stops somebody from making an export public with one policy. `tmp-test-ana` has no owner, which
is lesson 24's subject, the resource nobody owns.

Read `verdict` for what it does not do. **It never calls S3.** Everything it knows came from the
configuration item, the tags and the supplementary configuration that Config recorded; that is what makes
a rule's verdict reproducible, since the item says exactly what was judged and when. A function that
asked S3 directly would be judging the bucket as it is at that moment, which may not be the version that
triggered it.

The last line is the honest part. A real invocation carries a `ResultToken`, and the evaluations are
recorded against the rule; with `TestMode`, as here, Config checks the evaluations and records nothing.
Zero rejected means the shape is right, which is what a lab can prove.
