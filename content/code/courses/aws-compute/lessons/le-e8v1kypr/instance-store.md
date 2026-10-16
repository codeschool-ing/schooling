---
title: Instance store, the disk that belongs to the host
version: 1
---

The `d` in a type name, and the whole `i` family, promise local NVMe disks, and local sounds like
safe: the disk is right there in the machine. **An instance store disk belongs to the host, not to
your instance**, and the instance only borrows it. When the instance leaves the host, by a stop, a
termination or a hardware failure, the disk stays behind and AWS erases it before
anybody else gets it. What it buys in exchange is speed, and a price already included in the
instance.

## Which types have one

moto carries the sizes AWS publishes:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types i4i.large i4i.xlarge c7gd.xlarge m7gd.large m7i.large --query "InstanceTypes[].[InstanceType,InstanceStorageSupported,InstanceStorageInfo.TotalSizeInGB,InstanceStorageInfo.Disks[0].Type]" --output table
------------------------------------------
|          DescribeInstanceTypes         |
+--------------+--------+-------+--------+
|  c7gd.xlarge |  True  |  237  |  ssd   |
|  i4i.large   |  True  |  468  |  ssd   |
|  i4i.xlarge  |  True  |  937  |  ssd   |
|  m7gd.large  |  True  |  118  |  ssd   |
|  m7i.large   |  False |  None |  None  |
+--------------+--------+-------+--------+
```

`i4i.large` has 468 GB and `i4i.xlarge` twice that, 937; `m7gd.large` has 118 and `c7gd.xlarge`
237, so the disk grows with the size like everything else. `m7i.large`, with no `d`, has none.

Launch one, and the instance store does not appear where the EBS volumes do:

```
ana@laptop:~/aws$ ID3=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type i4i.large --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$ID3" --query "Reservations[0].Instances[0].[InstanceType,RootDeviceType,BlockDeviceMappings[].DeviceName]" --output text
i4i.large	ebs
/dev/sda1
```

The only mapping is the EBS root, `/dev/sda1`, and `RootDeviceType` says `ebs`. **That is also
how AWS shows it**: on the Nitro types the NVMe instance store is attached automatically and is not
listed in the block device mapping. Inside the instance it is a device of its own, such as
`/dev/nvme1n1`, with no file system on it, which you format and mount at every boot, because it
starts empty every time the instance starts on a new host. moto has no disk to give, so none of that
could be run here.

Because the disk starts empty on every new host, preparing it is part of every boot, not a step
done once. The usual way is a few lines in the instance's user data, or a systemd unit baked into
the image, that format the device and mount it before the application starts. Lesson 7 is about
user data; what matters here is that an application which expects the directory to exist must
not start before that step has run.

## What survives what

| | instance store | EBS volume |
|---|---|---|
| reboot | kept | kept |
| stop and start | **erased** | kept |
| terminate | **erased** | deleted or kept, by its flag |
| the host fails | **lost** | kept, in its zone |
| a snapshot | not possible | yes |

The fourth row is the one that catches people. Nobody chooses a host failure, and AWS also retires
hosts on a schedule of its own, sending a notice that the instance will be stopped. An instance
store holding the only copy of anything is a loss waiting for one of those, and an auto scaling
group replacing an unhealthy instance, lesson 4, is the same event from a different direction.

## What it is for

**Data that is either temporary or copied somewhere else.** Within those two kinds it is the best
disk EC2 has:

- a **cache**: a CDN's edge cache, a build cache, a local copy of something whose original is in
  S3; losing it costs a refill and nothing else;
- **scratch space**: the shuffle files of a Spark job, the temporary tables of a large sort,
  intermediate frames of a video encode;
- **databases that replicate themselves**, such as Cassandra or a Kafka cluster, where each node's
  data is also on two others and a node that loses its disk is rebuilt from its peers. This is what
  the `i` family is designed around.

What it is not for is the one copy of a database, uploads users sent, or anything somebody would
be asked to restore.

## The price of it

The disk costs nothing separately, but the type carrying it costs more. The price sheet of 16
October 2026 makes the comparison exact, because `i4i.large` and `r7i.large` have the same 2 vCPU
and 16 GiB:

| | per hour | per month of 730 hours |
|---|---|---|
| `r7i.large` | 0.21105 | 154.07 USD |
| `i4i.large` | 0.274 | 200.02 USD |
| the difference, 468 GB of NVMe | 0.06295 | 45.95 USD |
| a `gp3` volume of 468 GB, for comparison | | 71.14 USD |

The local disk costs about two thirds of an equally large `gp3` volume, and a `gp3` volume's
included 3,000 IOPS are a small fraction of what a local NVMe disk does. **What the difference
buys is durability**, which the instance store does not have at all. For a cache that is a good
trade; for the only copy of anything it is not one at any price.
