---
title: EFS, one file system for many instances
version: 1
---

When two web servers need the same uploaded files, the first idea is a bigger EBS volume both can
use. **EBS is a disk for one instance in one zone; EFS is a file system for many, across zones.**
It speaks NFS, the network file system protocol Linux has had for decades, and an instance mounts it
the way it would mount a share from a file server. Nothing is provisioned: it grows as files are
written, shrinks as they are deleted, and is billed for the bytes it holds.

```schooling-figure
{"svg": "<svg id=\"fig-zones\" viewBox=\"0 0 720 344\" role=\"img\" aria-label=\"The region sa-east-1 with three zones. In sa-east-1a an instance has an EBS volume attached. A volume in sa-east-1b cannot be attached to that instance: AWS refuses an attachment from another zone. Each zone has an EFS mount target with an address in its own subnet, 172.31.0.4, 172.31.16.4 and 172.31.32.4, and the instance in each zone reaches the one EFS file system of the region through the target in its zone.\"><defs><marker id=\"zones-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"12\" width=\"696\" height=\"320\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1, the region</text><rect x=\"28\" y=\"40\" width=\"208\" height=\"208\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"132\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"44\" y=\"68\" width=\"176\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"132\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">instance</text><rect x=\"44\" y=\"196\" width=\"176\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">mount target</text><text x=\"212\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.0.4</text><line x1=\"188\" y1=\"108\" x2=\"188\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><line x1=\"132\" y1=\"234\" x2=\"132\" y2=\"266\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><rect x=\"44\" y=\"126\" width=\"84\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"86\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EBS volume</text><rect x=\"256\" y=\"40\" width=\"208\" height=\"208\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"272\" y=\"68\" width=\"176\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">instance</text><rect x=\"272\" y=\"196\" width=\"176\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"282\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">mount target</text><text x=\"440\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.16.4</text><line x1=\"416\" y1=\"108\" x2=\"416\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><line x1=\"360\" y1=\"234\" x2=\"360\" y2=\"266\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><rect x=\"272\" y=\"126\" width=\"84\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"314\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EBS volume</text><rect x=\"484\" y=\"40\" width=\"208\" height=\"208\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"588\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"500\" y=\"68\" width=\"176\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">instance</text><rect x=\"500\" y=\"196\" width=\"176\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">mount target</text><text x=\"668\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.32.4</text><line x1=\"644\" y1=\"108\" x2=\"644\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><line x1=\"588\" y1=\"234\" x2=\"588\" y2=\"266\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><line x1=\"72\" y1=\"108\" x2=\"72\" y2=\"124\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><path d=\"M 256 146 L 208 104\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#zones-ah)\"></path><text x=\"314\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refused across zones</text><rect x=\"28\" y=\"268\" width=\"664\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">EFS file system: one per region, reached in every zone</text></svg>", "caption": "A volume never leaves its zone. A file system is reached from every zone, through the mount target in each."}
```

The figure is the difference in one picture. A volume and the instance using it sit in one zone,
and an attachment from another zone is refused. The file system belongs to the region and is
reached in each zone through a **mount target**, a network interface with an address in that zone's
subnet. An instance mounts the target in its own zone, and every instance sees the same files.

## Creating one

```
ana@laptop:~/aws$ FS=$(aws efs create-file-system --creation-token uploads-2026 --encrypted --tags Key=Name,Value=uploads --query FileSystemId --output text)
ana@laptop:~/aws$ aws efs describe-file-systems --file-system-id "$FS"
{
    "FileSystems": [
        {
            "OwnerId": "123456789012",
            "CreationToken": "uploads-2026",
            "FileSystemId": "fs-60519bb2",
            "FileSystemArn": "arn:aws:elasticfilesystem:sa-east-1:123456789012:file-system/fs-60519bb2",
            "CreationTime": "2026-10-16T13:38:47.212031-03:00",
            "LifeCycleState": "available",
            "Name": "uploads",
            "NumberOfMountTargets": 0,
            "SizeInBytes": {
                "Value": 0,
                "Timestamp": "2026-10-16T13:38:47.886142-03:00",
                "ValueInIA": 0,
                "ValueInStandard": 0
            },
            "PerformanceMode": "generalPurpose",
            "Encrypted": true,
            "ThroughputMode": "bursting",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "uploads"
                }
            ]
        }
    ]
}
```

The answer is AWS's shape. Three things in it are worth reading. `Encrypted` is `true` because the
request asked for it, and it cannot be switched on later; a file system created unencrypted stays
that way. `PerformanceMode` is `generalPurpose`, the one to choose unless AWS's guidance for a
specific workload says otherwise. And `ThroughputMode` is `bursting`, the value when the request
names none: throughput then grows with the amount stored, which a small file system has little of.
**AWS recommends `elastic` for spiky or unpredictable workloads**, where throughput follows demand
and each gigabyte read or written is billed, at a price the sheet does not print.

`SizeInBytes` is 0, and in moto it stays 0, because moto serves no NFS and holds no files.

## Mount targets, one per zone

A mount target is reached over the network on TCP port 2049, so it needs a security group that
allows it, and it needs a subnet in each zone that will mount it:

```
ana@laptop:~/aws$ VPC=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ SG=$(aws ec2 create-security-group --group-name efs-nfs --description "NFS from inside the VPC" --vpc-id "$VPC" --query GroupId --output text)
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 2049 --cidr 172.31.0.0/16 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text
tcp	2049	172.31.0.0/16
ana@laptop:~/aws$ for s in $(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" --query "Subnets[].SubnetId" --output text); do aws efs create-mount-target --file-system-id "$FS" --subnet-id "$s" --security-groups "$SG" --query "[MountTargetId,AvailabilityZoneName,IpAddress]" --output text; done
fsmt-191fccb7	sa-east-1a	172.31.0.4
fsmt-50da50b9	sa-east-1b	172.31.16.4
fsmt-22c08967	sa-east-1c	172.31.32.4
```

The security group lets port 2049 in from the whole default VPC, `172.31.0.0/16`; on a real
deployment the source would be the web servers' own security group, `aws-foundations` lesson 18's
pattern, rather than an address range. Then one mount target per subnet of the default VPC, which
has one subnet per zone, and each target has an address in its zone's range.

**A file system has at most one mount target per zone**, and AWS and moto agree on that:

```
ana@laptop:~/aws$ A=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" Name=availability-zone,Values=sa-east-1a --query "Subnets[0].SubnetId" --output text)
ana@laptop:~/aws$ aws efs create-mount-target --file-system-id "$FS" --subnet-id "$A" --security-groups "$SG"

aws: [ERROR]: An error occurred (MountTargetConflict) when calling the CreateMountTarget operation: mount target already exists in this AZ
ana@laptop:~/aws$ aws efs describe-file-systems --file-system-id "$FS" --query "FileSystems[0].[NumberOfMountTargets,ThroughputMode,SizeInBytes.Value]" --output text
3	bursting	0
```

An instance in `sa-east-1a` mounts `172.31.0.4`, or better, the file system's DNS name, which
resolves in each zone to the target in that zone. That is the step this lesson cannot run. On AWS,
with Amazon's own mount helper, `amazon-efs-utils`, installed on the instance, it is one line, and
the `tls` option encrypts the traffic on the way:

```sh
sudo dnf install -y amazon-efs-utils
sudo mkdir -p /mnt/uploads
sudo mount -t efs -o tls fs-0123456789abcdef0:/ /mnt/uploads
```

These commands were not run; moto has no file system to mount and no instance to mount it on.
`fs-0123456789abcdef0` stands for your file system's id, which on AWS has seventeen characters
after the `fs-` where moto's has eight.

## What it costs, and what it is for

The price sheet of 16 October 2026 has EFS Standard at **0.57 USD per GB-month**, against 0.152 for
`gp3`: three and three quarter times as much per gigabyte. Two things narrow the gap. EFS is billed
for what is stored, where a volume is billed for what was provisioned. And it is one copy for every
instance, where volumes are one each:

| | stored or provisioned | per month |
|---|---|---|
| EFS, 40 GB of uploads, shared by four web servers | 40 GB stored | 22.80 USD |
| a 100 GB `gp3` volume on each of the four | 400 GB provisioned | 60.80 USD |

The volumes are cheaper per gigabyte and dearer in total, and they do not share anything, which was
the requirement. EFS also has Infrequent Access and Archive storage classes, at lower prices the
sheet does not carry, with a lifecycle policy that moves files nobody has read for a set number of
days.

It fits **files several machines read and write**: uploads, a content management system's media,
home directories, a dataset many workers read, the shared volume of containers in ECS and EKS,
which lessons 8 and 11 come back to. It fits a database badly: every operation crosses the network
to a regional service, so each one takes longer than on a local block device, and databases are
built around exactly that latency. A database belongs on EBS, or in a managed database service.
