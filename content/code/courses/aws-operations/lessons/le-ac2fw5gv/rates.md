---
title: The rates, from the price list
version: 1
---

The prices of every option are in AWS's public price list, in two offer files: EC2's, with on-demand and
reserved prices, and the Compute Savings Plans', with each plan's rate for each kind of usage. Both are
large, about 290 MB and 240 MB for São Paulo alone, so `rates.py`, in `~/aws/commit`, downloads them once
into the same cache as lesson 1's `price.py`, pinned to a version like it, and keeps only the lines for one
instance type. It needs about a gigabyte of memory while it reads each file.

```python
# rates.py: one instance type's price per hour in sa-east-1, on demand and under each commitment
#   python3 rates.py m7g.large
import json
import os
import sys
import urllib.request

CACHE = os.path.expanduser("~/.cache/aws-prices")
BASE = "https://pricing.us-east-1.amazonaws.com"
EC2 = BASE + "/offers/v1.0/aws/AmazonEC2/20261015191316/sa-east-1/index.json"
SP = BASE + "/savingsPlan/v1.0/aws/AWSComputeSavingsPlan/20261013035015/sa-east-1/index.json"
HOURS = {"1yr": 8760, "3yr": 26280}


def load(url):  # about 290 MB and 240 MB, downloaded once, and a minute to read
    path = os.path.join(CACHE, url.split("/aws/")[1].replace("/", "-"))
    if not os.path.exists(path):
        os.makedirs(CACHE, exist_ok=True)
        urllib.request.urlretrieve(url, path + ".part")
        os.rename(path + ".part", path)
    with open(path) as f:
        return json.load(f)


itype = sys.argv[1]
usage = f"SAE1-BoxUsage:{itype}"  # Linux, shared tenancy, in São Paulo
rows = []

ec2 = load(EC2)
for sku, product in ec2["products"].items():
    a = product["attributes"]
    if (a.get("usagetype"), a.get("operation"), a.get("preInstalledSw"), a.get("capacitystatus")) \
            != (usage, "RunInstances", "NA", "Used"):
        continue
    for term in ec2["terms"]["OnDemand"].get(sku, {}).values():
        for d in term["priceDimensions"].values():
            rows.append(("on demand", "", 0.0, float(d["pricePerUnit"]["USD"])))
    for term in ec2["terms"].get("Reserved", {}).get(sku, {}).values():
        t, upfront, hourly = term["termAttributes"], 0.0, 0.0
        for d in term["priceDimensions"].values():
            if d["unit"] == "Quantity":
                upfront = float(d["pricePerUnit"]["USD"])
            else:
                hourly = float(d["pricePerUnit"]["USD"])
        years = t["LeaseContractLength"]
        rows.append((f"RI {t['OfferingClass']}", f"{years} {t['PurchaseOption']}", upfront,
                     hourly + upfront / HOURS[years]))
published = ec2["publicationDate"][:10]
del ec2

sp = load(SP)
plans = {p["sku"]: p["attributes"] for p in sp["products"]}
for term in sp["terms"]["savingsPlan"]:
    a = plans[term["sku"]]
    instance_plan = a["productFamily"] == "EC2InstanceSavingsPlans"
    if instance_plan and a["instanceType"] != itype.split(".")[0]:
        continue
    for r in term["rates"]:
        if r["discountedUsageType"] == usage and r["discountedOperation"] == "RunInstances":
            name = "EC2 Instance SP" if instance_plan else "Compute SP"
            rows.append((name, f"{a['purchaseTerm']} {a['purchaseOption']}", None,
                         float(r["discountedRate"]["price"])))

print(f"{itype}, Linux, sa-east-1; EC2 prices published {published}, plans {sp['publicationDate'][:10]}")
on_demand = rows[0][3]
for name, term, upfront, hourly in sorted(rows, key=lambda r: -r[3]):
    paid = "" if upfront is None else f"{upfront:8.0f}"
    print(f"  {name:<17} {term:<23} {paid:>8}  {hourly:.4f}/h  {1 - hourly / on_demand:4.0%} off")
```

```
ana@laptop:~/aws/commit$ python3 rates.py m7g.large
m7g.large, Linux, sa-east-1; EC2 prices published 2026-10-15, plans 2026-10-13
  on demand                                        0  0.1301/h    0% off
  RI convertible    1yr No Upfront                 0  0.0884/h   32% off
  Compute SP        1yr No Upfront                    0.0884/h   32% off
  RI convertible    1yr Partial Upfront          369  0.0842/h   35% off
  Compute SP        1yr Partial Upfront               0.0842/h   35% off
  Compute SP        1yr All Upfront                   0.0825/h   37% off
  RI convertible    1yr All Upfront              722  0.0824/h   37% off
  RI standard       1yr No Upfront                 0  0.0806/h   38% off
  EC2 Instance SP   1yr No Upfront                    0.0806/h   38% off
  EC2 Instance SP   1yr Partial Upfront               0.0768/h   41% off
  RI standard       1yr Partial Upfront          336  0.0768/h   41% off
  RI standard       1yr All Upfront              659  0.0752/h   42% off
  EC2 Instance SP   1yr All Upfront                   0.0752/h   42% off
  RI convertible    3yr No Upfront                 0  0.0675/h   48% off
  Compute SP        3yr No Upfront                    0.0675/h   48% off
  Compute SP        3yr Partial Upfront               0.0625/h   52% off
  RI convertible    3yr Partial Upfront          821  0.0624/h   52% off
  RI convertible    3yr All Upfront             1609  0.0612/h   53% off
  Compute SP        3yr All Upfront                   0.0612/h   53% off
  RI standard       3yr No Upfront                 0  0.0588/h   55% off
  EC2 Instance SP   3yr No Upfront                    0.0588/h   55% off
  RI standard       3yr Partial Upfront          715  0.0544/h   58% off
  EC2 Instance SP   3yr Partial Upfront               0.0544/h   58% off
  EC2 Instance SP   3yr All Upfront                   0.0512/h   61% off
  RI standard       3yr All Upfront             1345  0.0512/h   61% off
```

The last column is the discount against the first line, 0.1301 USD an hour on demand. For a reserved
instance the upfront payment is spread over the term's hours, so every line is comparable.

## What the table says

**The plans and the reservations cost the same.** Every Savings Plan line has an RI line at the same
rate: the Compute Savings Plan matches the convertible RI, and the EC2 Instance Savings Plan matches the
standard RI, term for term and payment for payment. So the choice between them is not about price; it is
about **what the commitment follows** when the fleet changes, and a Savings Plan follows more.

**The term is worth more than the payment option.** Going from one year to three moves the discount from
32% to 48% with no upfront; paying everything upfront within the same term adds 5 points at most. A team
unsure whether it will exist in three years is right to take one, and paying upfront is mostly a question
of where the cash is better kept.

**Flexibility costs about 6 points.** The Compute plan, which follows the workload to another family,
region or to Fargate, gives 32% where the instance plan tied to `m7g` in São Paulo gives 38%. For a fleet
that will move to a new generation of instances during the term, the six points are cheap.
