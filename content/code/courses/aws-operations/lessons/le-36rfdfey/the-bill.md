---
title: Reading the bill by owner and by usage type
version: 1
---

The detailed bill is the **Cost and Usage Report**, CUR: one line per resource, per usage type, per hour
or day, with a column for each activated tag, delivered to a bucket as CSV or Parquet. Its line items use
the same **usage types** as the price list of lesson 1, `SAE1-BoxUsage:m7g.large` and the rest, which is
what makes a bill readable by somebody who has read the price list.

moto produces no bill, so the shop's month is written by hand here, abridged to four of CUR's columns, its
twenty lines made of the resources and prices of the lessons before this one:

```sh
cd ~/aws/owners
cat > bill.csv <<'CSV'
line_item_usage_type,line_item_resource_id,line_item_unblended_cost,resource_tags_user_owner
SAE1-BoxUsage:m7g.xlarge,i-0api1,189.87,api
SAE1-BoxUsage:m7g.xlarge,i-0api2,189.87,api
SAE1-BoxUsage:m7g.2xlarge,i-0worker,379.75,checkout
SAE1-BoxUsage:m7g.large,i-0stg1,94.97,platform
SAE1-BoxUsage:m7g.large,i-0stg2,94.97,platform
SAE1-BoxUsage:m7g.large,i-0stg3,94.97,
SAE1-BoxUsage:m7g.large,i-0stg4,94.97,
SAE1-EBS:VolumeUsage.gp3,vol-0lab200,30.40,
SAE1-EBS:SnapshotUsage,snap-0migration,6.80,
SAE1-PublicIPv4:IdleAddress,eipalloc-0spare,3.65,
SAE1-TimedStorage-ByteHrs,shop-orders,41.20,checkout
SAE1-Requests-Tier1,shop-orders,12.10,checkout
SAE1-TimedStorage-ByteHrs,tmp-test-ana,18.40,
SAE1-DataTransfer-Out-Bytes,,180.00,
SAE1-WebACLV2,shop,5.00,platform
SAE1-RequestV2-Tier1,shop,30.00,platform
SAE1-RuleV2,shop,3.00,platform
SAE1-DataProcessing-Bytes,/shop/api,52.30,api
sa-east-1-KMS-Keys,alias/shop-orders,1.00,platform
SAE1-AWSSecretsManager-Secrets,shop/prod/db,2.40,platform
CSV
```

`bill.py` adds it up two ways, by owner and by usage type, and lists what nobody owns:

```python
# bill.py: a month's line items, by owner and by usage type
import collections
import csv

by_owner, by_usage = collections.Counter(), collections.Counter()
nobody = []
for row in csv.DictReader(open("bill.csv")):
    cost = float(row["line_item_unblended_cost"])
    owner = row["resource_tags_user_owner"] or "(nobody)"
    by_owner[owner] += cost
    by_usage[row["line_item_usage_type"]] += cost
    if owner == "(nobody)":
        nobody.append((cost, row["line_item_usage_type"], row["line_item_resource_id"] or "(no resource)"))

total = sum(by_owner.values())
print(f"total {total:.2f} USD")
for owner, cost in by_owner.most_common():
    print(f"  {owner:<10} {cost:>8.2f}  {cost / total:4.0%}")
print("largest usage types:")
for usage, cost in by_usage.most_common(4):
    print(f"  {usage:<28} {cost:>8.2f}")
print("owned by nobody:")
for cost, usage, resource in sorted(nobody, reverse=True):
    print(f"  {cost:>8.2f}  {usage:<28} {resource}")
```

```
ana@laptop:~/aws/owners$ python3 bill.py
total 1525.62 USD
  checkout     433.05   28%
  api          432.04   28%
  (nobody)     429.19   28%
  platform     231.34   15%
largest usage types:
  SAE1-BoxUsage:m7g.large        379.88
  SAE1-BoxUsage:m7g.2xlarge      379.75
  SAE1-BoxUsage:m7g.xlarge       379.74
  SAE1-DataTransfer-Out-Bytes    180.00
owned by nobody:
    180.00  SAE1-DataTransfer-Out-Bytes  (no resource)
     94.97  SAE1-BoxUsage:m7g.large      i-0stg4
     94.97  SAE1-BoxUsage:m7g.large      i-0stg3
     30.40  SAE1-EBS:VolumeUsage.gp3     vol-0lab200
     18.40  SAE1-TimedStorage-ByteHrs    tmp-test-ana
      6.80  SAE1-EBS:SnapshotUsage       snap-0migration
      3.65  SAE1-PublicIPv4:IdleAddress  eipalloc-0spare
```

**More than a quarter of the month, 429.19 USD, belongs to nobody.** It splits into two kinds, and they
need different answers.

**Resources without the tag.** Two of the four staging instances were launched by hand and never tagged;
the volume, the snapshot and the address are lesson 23's idle four; `tmp-test-ana` is the bucket the
previous section found. Each is a resource with an id, and each is fixed by giving it an owner or
deleting it.

**Costs that have no resource at all.** Data transfer out of the region, 180 USD here, is billed to the
account, not to any instance, and no tag can be put on it. Neither can support plans, taxes or most
credits. These are **shared costs**, and the honest answer is a rule for dividing them, which is the
next section.

The usage types say something else: three instance sizes are three quarters of the bill, which is where
lesson 22's commitments and lesson 23's rightsizing apply. Reading the bill by usage type tells where the
money goes; reading it by owner tells who can change it.
