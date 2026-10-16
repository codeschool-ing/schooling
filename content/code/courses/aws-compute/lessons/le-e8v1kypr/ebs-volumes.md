---
title: EBS volumes, and the three numbers you choose
version: 1
---

A disk is usually bought by size, and a faster disk is a more expensive model of the same size.
**An EBS volume is three numbers, and on `gp3` you set them apart**: the gigabytes it holds, the
input and output operations per second it may do (IOPS), and the megabytes per second it may move
(throughput). It is a block device served over the network from storage in one Availability Zone,
attached to an instance as if it were a local disk, and billed for what you provisioned, whether it
is used or not.

## The volume types

| type | made of | performance | for |
|---|---|---|---|
| `gp3` | SSD | 3,000 IOPS and 125 MiB/s included at any size; more is bought separately | almost everything: root disks, most databases |
| `gp2` | SSD | 3 IOPS per GiB, so performance only grows with size | volumes created before `gp3` existed |
| `io2` | SSD | the IOPS you provision, up to 1,000 per GiB | databases that need a guaranteed rate and higher durability |
| `st1` | hard disk | throughput that grows with size; poor at random IOPS | large sequential reads: logs, data pipelines |
| `sc1` | hard disk | the lowest throughput | data read rarely, at the lowest price |

**`gp3` is the default answer**, and the reason is in the first column of numbers. On `gp2` a
100 GiB volume gets 300 IOPS, and the only way to get 3,000 is to buy 1,000 GiB nobody needs. On
`gp3` every volume starts at 3,000 and 125 MiB/s, and the extra is a separate line on the bill.
`io2` adds durability as well as rate: AWS states 99.999% for it, against 99.8% to 99.9% for the
others. The two hard-disk types cannot be a boot volume, and AWS sells them from 125 GiB upwards.

Each type, created in moto:

```
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3
{
    "Iops": 3000,
    "VolumeType": "gp3",
    "VolumeId": "vol-63a9f0f2cdbd8b807",
    "Size": 100,
    "AvailabilityZone": "sa-east-1a",
    "State": "available",
    "CreateTime": "2026-10-16T16:38:15+00:00",
    "Attachments": [],
    "Encrypted": false
}
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --iops 6000 --throughput 250 --query "[VolumeType,Size,Iops,Throughput]" --output text
gp3	100	6000	250
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp2 --query "[VolumeType,Size,Iops]" --output text
gp2	100	None
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type io2 --iops 10000 --query "[VolumeType,Size,Iops]" --output text
io2	100	10000
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 500 --volume-type st1 --query "[VolumeType,Size,Iops]" --output text
st1	500	None
```

The shapes are AWS's, and two of the numbers are moto's. **On AWS the first answer carries a
`Throughput` of 125**, the included baseline, which moto leaves out; and the `gp2` volume has 300
IOPS, three per GiB, where moto reports none. moto keeps the numbers you give it and computes few of
its own.

It also keeps numbers AWS would refuse:

```
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --iops 90000 --query "[VolumeType,Size,Iops]" --output text
gp3	100	90000
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 10 --volume-type st1 --query "[VolumeType,Size]" --output text
st1	10
```

A `gp3` volume may have at most 500 IOPS per GiB, so 100 GiB stops at 50,000, and AWS rejects
90,000. An `st1` volume of 10 GiB is below the 125 GiB minimum and is rejected too. **In both cases
moto created the volume.** As with the architecture check in lesson 1, the habit is to know the
limits yourself, because the first place you meet the refusal should not be a deployment.

## What a volume costs

The price sheet of 16 October 2026 has every line needed, per month in `sa-east-1`:

| volume | arithmetic | per month |
|---|---|---|
| `gp3`, 100 GB, the included 3,000 IOPS and 125 MiB/s | 100 × 0.152 | 15.20 USD |
| the same, raised to 6,000 IOPS | + 3,000 × 0.0095 | + 28.50 USD |
| and to 250 MiB/s | + 125 × 0.076 | + 9.50 USD |
| **the second `gp3` above, in total** | | **53.20 USD** |
| `io2`, 100 GB, storage only | 100 × 0.238 | 23.80 USD |
| `st1`, 500 GB | 500 × 0.086 | 43.00 USD |

Doubling the performance of that `gp3` volume cost two and a half times what the gigabytes
did, which is why performance is the number to measure before raising. The `io2` line is storage
alone: its provisioned IOPS are billed per IOPS-month as well, at a price the sheet does not
print, and for a 10,000-IOPS volume that line is the larger one. The `st1` volume holds five times
as much as the first `gp3` for under three times the price, which is the case for it, provided
the reads are large and in order.

## The instance has a limit too

A volume's IOPS and throughput are what the volume can do. **What reaches the instance is capped by
the instance type as well**, because EBS travels over the network, and every type has a bandwidth
for it:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types m7i.large m7i.2xlarge m7i.8xlarge --query "InstanceTypes[].[InstanceType,EbsInfo.EbsOptimizedInfo.BaselineThroughputInMBps,EbsInfo.EbsOptimizedInfo.BaselineIops,EbsInfo.EbsOptimizedInfo.MaximumThroughputInMBps]" --output table
----------------------------------------------
|            DescribeInstanceTypes           |
+--------------+---------+--------+----------+
|  m7i.2xlarge |  312.5  |  12000 |  1250.0  |
|  m7i.8xlarge |  1250.0 |  40000 |  1250.0  |
|  m7i.large   |  81.25  |  3600  |  1250.0  |
+--------------+---------+--------+----------+
```

`m7i.large` is guaranteed 81.25 MB/s and 3,600 IOPS to EBS across all its volumes together, and
may burst to 1,250 MB/s for a while, like its network in lesson 1. A volume provisioned at 250 MiB/s
on that instance pays for throughput the instance can sustain only in bursts. The baseline grows
with the size, so `m7i.2xlarge` sustains 312.5 MB/s and `m7i.8xlarge` reaches the peak. **Size the
volume and the instance together**; raising one without the other buys a number nothing can use.

## What moto cannot show

None of these volumes holds a byte. moto keeps the record and serves no blocks, so nothing here was
formatted, mounted or measured, and the IOPS and throughput figures above are promises from AWS's
documentation rather than readings. The way to measure a real volume is a benchmark such as `fio`
inside an instance on AWS, which is outside what this course can run.
