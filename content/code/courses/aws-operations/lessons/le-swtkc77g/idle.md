---
title: Idle resources, found by a program
version: 1
---

The cheapest saving on a bill is a resource nobody uses: it costs the same every hour, does nothing, and
removing it changes nothing for anybody. They accumulate the same way in every account: a disk detached
from an instance that was terminated, an address kept after its server went, an instance stopped "for
now" eight months ago, the snapshots of a volume that no longer exists. None of them appears on a
dashboard, because a dashboard shows what works.

The lab makes one of each, in `~/aws/rightsize` (`mkdir -p ~/aws/rightsize && cd ~/aws/rightsize`):

```sh
AMI=$(aws ec2 describe-images --owners amazon --query 'Images[0].ImageId' --output text)
aws ec2 run-instances --image-id $AMI --instance-type m7g.large --count 2 --query 'Instances[].InstanceId' --output text
OLD=$(aws ec2 describe-instances --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws ec2 stop-instances --instance-ids $OLD --query 'StoppingInstances[0].CurrentState.Name'
aws ec2 create-volume --availability-zone sa-east-1a --size 200 --volume-type gp3 --query VolumeId --output text
aws ec2 allocate-address --domain vpc --query AllocationId --output text
GONE=$(aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --query VolumeId --output text)
aws ec2 create-snapshot --volume-id $GONE --description 'before the migration' --query SnapshotId --output text
aws ec2 delete-volume --volume-id $GONE
```

`idle.py` asks EC2 for each kind and prices what it finds, with the São Paulo prices the next part of
this section reads from the price list:

```python
# idle.py: what in this region is paid for and does nothing, and what it costs a month
import boto3

GP3_GB_MONTH = 0.152  # SAE1-EBS:VolumeUsage.gp3
SNAPSHOT_GB_MONTH = 0.068  # SAE1-EBS:SnapshotUsage, if every block were stored
IDLE_IPV4_HOUR = 0.005  # SAE1-PublicIPv4:IdleAddress
HOURS = 730

ec2 = boto3.client("ec2")
found = []

volumes = ec2.describe_volumes()["Volumes"]
for v in volumes:
    if v["State"] == "available":
        found.append(("volume, attached to nothing", v["VolumeId"], v["Size"] * GP3_GB_MONTH))

for a in ec2.describe_addresses()["Addresses"]:
    if "AssociationId" not in a:
        found.append(("public IPv4, idle", a["AllocationId"], IDLE_IPV4_HOUR * HOURS))

stopped = ec2.describe_instances(Filters=[{"Name": "instance-state-name", "Values": ["stopped"]}])
for r in stopped["Reservations"]:
    for i in r["Instances"]:
        ids = [m["Ebs"]["VolumeId"] for m in i.get("BlockDeviceMappings", [])]
        size = sum(v["Size"] for v in volumes if v["VolumeId"] in ids)
        found.append(("instance, stopped, its disks", i["InstanceId"], size * GP3_GB_MONTH))

me = boto3.client("sts").get_caller_identity()["Account"]
live = {v["VolumeId"] for v in volumes}
for s in ec2.describe_snapshots(OwnerIds=["self"])["Snapshots"]:
    if s["OwnerId"] == me and s["VolumeId"] not in live:
        found.append(("snapshot of a deleted volume", s["SnapshotId"], s["VolumeSize"] * SNAPSHOT_GB_MONTH))

for kind, rid, usd in found:
    print(f"{kind:<30} {rid:<24} {usd:8.2f} USD a month")
print(f"{'total':<55} {sum(u for _, _, u in found):8.2f} USD a month")
```

```
ana@laptop:~/aws/rightsize$ python3 idle.py
volume, attached to nothing    vol-cf446da070549843f       30.40 USD a month
public IPv4, idle              eipalloc-bceaa6620f2bd0dc8     3.65 USD a month
instance, stopped, its disks   i-00301edfa1d4a6f6c          1.22 USD a month
snapshot of a deleted volume   snap-54fe7e295470e848f       6.80 USD a month
total                                                      42.07 USD a month
```

Four things doing nothing, 42.07 USD a month, **about 505 USD a year**, and this account is a lab with two
instances. The owner check in the snapshot loop is there for moto: asked for the account's own snapshots,
it also returns the thousand-odd behind its sample images, which belong to another account, and AWS
would not. A snapshot that an image of the account still uses is not idle either, and a fuller program
would check `describe-images` for it. The stopped instance is the one people misread: **a stopped instance costs nothing for its
compute and everything for its disks**, which keep their price whether anything is running.

## The prices

The disk and snapshot prices are in EC2's offer, which lesson 22's `rates.py` already downloaded; a small
program reads two lines out of it, `ec2lines.py`:

```python
# ec2lines.py: lines of the EC2 offer that lesson 22's rates.py downloaded, by usage type
import json
import os
import sys

path = os.path.expanduser("~/.cache/aws-prices/AmazonEC2-20261015191316-sa-east-1-index.json")
with open(path) as f:
    offer = json.load(f)
lines = set()
for sku, product in offer["products"].items():
    usage = product["attributes"].get("usagetype")
    if usage in sys.argv[1:]:
        for term in offer["terms"]["OnDemand"].get(sku, {}).values():
            for d in term["priceDimensions"].values():
                lines.add(f"{usage:<26} {d['description']}")
print("\n".join(sorted(lines)))
```

The address is in the VPC offer, which is small enough to read with `curl` and `jq`, as lesson 16 read
Shield's:

```
ana@laptop:~/aws/rightsize$ python3 ec2lines.py SAE1-EBS:VolumeUsage.gp3 SAE1-EBS:SnapshotUsage
SAE1-EBS:SnapshotUsage     $0.068 per GB-Month of snapshot data stored - South America (Sao Paulo)
SAE1-EBS:VolumeUsage.gp3   $0.152 per GB-month of General Purpose (gp3) provisioned storage - South America (Sao Paulo)
ana@laptop:~/aws/rightsize$ curl -sS https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonVPC/20260917190528/sa-east-1/index.json | jq -r '.products as $p | .terms.OnDemand | to_entries[] | select($p[.key].attributes.usagetype | test("IdleAddress")) | .value[].priceDimensions[] | [.pricePerUnit.USD, .description] | @tsv'
0.0050000000	$0.005 per Idle public IPv4 address per hour
```

**15.2 cents per GB-month of gp3**, **6.8 cents per GB-month of snapshot**, and **half a cent an hour for a
public IPv4 address**, idle or not: AWS charges for every public IPv4 address since 2024, in use or idle,
and the idle line is the one nobody notices. A snapshot is billed for the blocks it stores, which for the
first snapshot of a volume is the data written to it, so `idle.py`'s figure for it is the most it can be.

## Before deleting

`idle.py` finds; it does not delete, and neither should anything automatic. **A disk attached to nothing
might be the only copy of something.** The order is: tag what was found with the date, tell the team, take
a snapshot of a volume before deleting it if anybody hesitates, and delete after a week of silence. A
snapshot of a 200 GB volume that holds 20 GB of data costs 1.36 USD a month; the volume costs 30.40.
