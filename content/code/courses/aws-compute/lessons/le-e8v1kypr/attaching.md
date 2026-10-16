---
title: Attaching, growing and outliving an instance
version: 1
---

Because an EBS volume travels over the network, it is easy to picture it as reachable from
anywhere, like a share. **A volume lives in one Availability Zone and attaches only to instances
in that zone.** It is replicated inside its zone, which is what makes it survive a failed disk. It
is not replicated outside it, so a zone that fails takes its volumes' availability with it, and
lesson 2's snapshots are how a volume moves.

## One zone, and moto does not check it

An instance in `sa-east-1a`, a volume in the same zone and one in `sa-east-1b`:

```
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7i.large --placement AvailabilityZone=sa-east-1a --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ DATA=$(aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --query VolumeId --output text)
ana@laptop:~/aws$ OTHER=$(aws ec2 create-volume --availability-zone sa-east-1b --size 100 --volume-type gp3 --query VolumeId --output text)
ana@laptop:~/aws$ aws ec2 attach-volume --volume-id "$DATA" --instance-id "$ID" --device /dev/sdf
{
    "VolumeId": "vol-fd3ae45872843be39",
    "InstanceId": "i-f1a1f240dc0908e71",
    "Device": "/dev/sdf",
    "State": "attaching",
    "AttachTime": "2026-10-16T16:38:30+00:00"
}
ana@laptop:~/aws$ aws ec2 attach-volume --volume-id "$OTHER" --instance-id "$ID" --device /dev/sdg --query State --output text
attaching
ana@laptop:~/aws$ aws ec2 describe-volumes --volume-ids "$DATA" "$OTHER" --query "Volumes[].[VolumeId,AvailabilityZone,State,Attachments[0].Device]" --output text
vol-fd3ae45872843be39	sa-east-1a	in-use	/dev/sdf
vol-cd4c70eb907c35f3b	sa-east-1b	in-use	/dev/sdg
```

The first attachment is the ordinary one. **The second would be refused on AWS** with
`InvalidVolume.ZoneMismatch`, because the volume and the instance are in different zones; moto
attached it anyway and lists it `in-use`. The way to give that instance the second volume's data is
the one lesson 2 showed: snapshot it, and create a volume from the snapshot in `sa-east-1a`.

The device name in the request, `/dev/sdf`, is a suggestion more than a name. On the Nitro types,
which is every current generation, the operating system sees an NVMe device such as `/dev/nvme1n1`,
and the order the devices appear in is not guaranteed to match the order you attached them. Inside
the instance a new volume is an empty block device: it is formatted once with `mkfs`, mounted, and
named in `/etc/fstab` by its file system UUID with the `nofail` option, so that a missing volume
does not stop the machine booting. None of that ran here, because moto's instance has no operating
system to run it in.

## Growing a volume while it is in use

Size, IOPS and throughput can all be changed on a volume that is attached and in use:

```
ana@laptop:~/aws$ aws ec2 modify-volume --volume-id "$DATA" --size 200 --iops 6000 --throughput 250
{
    "VolumeModification": {
        "VolumeId": "vol-fd3ae45872843be39",
        "ModificationState": "completed",
        "TargetSize": 200,
        "TargetIops": 6000,
        "TargetThroughput": 250,
        "OriginalSize": 100,
        "OriginalIops": 3000,
        "Progress": 100,
        "StartTime": "2026-10-16T16:38:35+00:00",
        "EndTime": "2026-10-16T16:38:35+00:00"
    }
}
```

moto finished the change at once. **On AWS a modification goes through `modifying` and
`optimizing` before `completed`**, which takes from minutes to hours on a large volume, and the
volume stays usable throughout, at the old performance until the change takes effect. AWS then asks
you to wait six hours before modifying the same volume again.

A larger volume does not make a larger file system. The partition and the file system inside are
still the old size until they are grown from inside the instance: `growpart` for the partition,
then `xfs_growfs` for XFS, which is what Amazon Linux uses, or `resize2fs` for ext4. That step was
not run here either.

The other direction is moto's leniency once more:

```
ana@laptop:~/aws$ aws ec2 modify-volume --volume-id "$DATA" --size 50 --query "VolumeModification.[ModificationState,OriginalSize,TargetSize]" --output text
completed	200	50
```

It shrank the volume from 200 to 50 GiB. **AWS never shrinks an EBS volume**, and refuses the
request; a smaller disk is a new volume and a copy of the files, made inside the operating system.

## Delete on termination

Every attachment carries one flag that decides what happens to the volume when the instance is
terminated:

```
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].BlockDeviceMappings[].[DeviceName,Ebs.VolumeId,Ebs.DeleteOnTermination]" --output text
/dev/sda1	vol-76af8a3bd7f326bb3	True
/dev/sdf	vol-fd3ae45872843be39	False
/dev/sdg	vol-cd4c70eb907c35f3b	False
```

The root volume, made from the image when the instance launched, has `DeleteOnTermination` set to
`True`. The two attached afterwards have `False`, which is the default for any volume attached to a
running instance. Terminating the instance shows what that means:

```
ana@laptop:~/aws$ ROOT=$(aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" --output text)
ana@laptop:~/aws$ aws ec2 terminate-instances --instance-ids "$ID" --query "TerminatingInstances[0].CurrentState.Name" --output text
shutting-down
ana@laptop:~/aws$ aws ec2 describe-volumes --volume-ids "$DATA" --query "Volumes[].[VolumeId,State,Size]" --output text
vol-fd3ae45872843be39	available	50
ana@laptop:~/aws$ aws ec2 describe-volumes --volume-ids "$ROOT"

aws: [ERROR]: An error occurred (InvalidVolume.NotFound) when calling the DescribeVolumes operation: The volume '{'vol-76af8a3bd7f326bb3'}' does not exist.
```

The root volume is gone, and the data volume is `available`, unattached and intact, with
everything on it, which is usually what you want for data. **It is also still billed.** A
forgotten 100 GB `gp3` volume is 15.20 USD a month on the price sheet of 16 October 2026, and an
account where every terminated test instance left one behind collects them silently. Finding them
is `aws ec2 describe-volumes --filters Name=status,Values=available`, and a team that runs it
weekly finds out who owns each.

The flag can be changed on a running instance, per device:

```
ana@laptop:~/aws$ ID2=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7i.large --placement AvailabilityZone=sa-east-1a --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ec2 attach-volume --volume-id "$DATA" --instance-id "$ID2" --device /dev/sdf --query State --output text
attaching
ana@laptop:~/aws$ aws ec2 modify-instance-attribute --instance-id "$ID2" --block-device-mappings "DeviceName=/dev/sdf,Ebs={DeleteOnTermination=true}"
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$ID2" --query "Reservations[0].Instances[0].BlockDeviceMappings[].[DeviceName,Ebs.DeleteOnTermination]" --output text
/dev/sda1	True
/dev/sdf	True
```

The data volume, attached to a new instance, will now be deleted with it. Set it this way for
scratch volumes that mean nothing without their instance, and leave it `False` for anything you
would want back. An auto scaling group, lesson 4, launches every instance from a template, and the
template's mapping is where this choice is made for a whole fleet.

## Stop, reboot and terminate, for a volume

| | reboot | stop | terminate |
|---|---|---|---|
| the instance | restarts on the same host | switched off, host released | deleted |
| an attached EBS volume | kept, attached | kept, attached, still billed | deleted if its flag says so, otherwise left `available` |
| instance store | kept | erased | erased |

The last row is the next section.
