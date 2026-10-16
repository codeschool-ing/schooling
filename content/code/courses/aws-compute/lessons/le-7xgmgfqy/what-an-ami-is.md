---
title: What an AMI is, and how to find the right one
version: 1
---

An AMI is usually pictured as a file, a disk image somebody uploaded, the way an ISO is a file. **An
AMI is a record that points at snapshots.** The record says what the machine needs to boot: the
processor architecture, how it boots, which device is the root disk. The snapshots hold the bytes.
Launching an instance reads the record, makes a new EBS volume from each snapshot it names, and
boots from the root one.

@@FIG:ami-anatomy@@

That split explains two facts that otherwise look arbitrary. An AMI belongs to **one region**,
because its snapshots are stored in that region, and its id means nothing anywhere else. And an AMI
costs money for as long as its snapshots exist, which is the last section of this lesson.

## Reading one

Amazon Linux 2023 is AWS's own distribution, and the next section shows how to find its current
image. Here is the image's record in full:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids ami-0b44997419d0b0d38
{
    "Images": [
        {
            "BlockDeviceMappings": [
                {
                    "Ebs": {
                        "DeleteOnTermination": false,
                        "SnapshotId": "snap-ff7826474c5a02103",
                        "VolumeSize": 15,
                        "VolumeType": "standard"
                    },
                    "DeviceName": "/dev/xvda"
                }
            ],
            "Description": "Amazon Linux 2023 AMI 2023.12.20260727.0 x86_64 HVM kernel-6.1",
            "Hypervisor": "xen",
            "ImageOwnerAlias": "amazon",
            "Name": "al2023-ami-2023.12.20260727.0-kernel-6.1-x86_64",
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "Tags": [],
            "VirtualizationType": "hvm",
            "BootMode": "uefi",
            "ImageId": "ami-0b44997419d0b0d38",
            "State": "available",
            "OwnerId": "137112412989",
            "CreationDate": "2026-10-16T16:25:15.000Z",
            "Public": true,
            "ProductCodes": [],
            "Architecture": "x86_64",
            "ImageType": "machine"
        }
    ]
}
```

The fields that decide whether a launch works are these:

| field | here | what it decides |
|---|---|---|
| `Architecture` | `x86_64` | which types it can run on; lesson 1 showed what moto lets through |
| `BootMode` | `uefi` | how the firmware starts it; some older types only boot `legacy-bios` |
| `VirtualizationType` | `hvm` | full hardware virtualisation, which every current type uses |
| `RootDeviceName` | `/dev/xvda` | which of the mapped disks is the root |
| `BlockDeviceMappings` | one, with a `SnapshotId` | the disks a new instance gets, and what each is made from |
| `OwnerId` | `137112412989` | the account that published it, here Amazon's |
| `Public` | `true` | any account may launch it |

**The block device mapping is the AMI.** Everything else is a description; the mapping is what
becomes a disk. It carries a size, a volume type and whether the volume is deleted when the
instance is terminated, and a launch may override any of them for its own copy: a larger root
volume, or `gp3` instead of what the image says.

This is also where moto's copy stops being AWS's. moto's record maps a 15 GB volume of type
`standard`, kept on termination, and dates the image to the second moto started; the 2023 build in
the name says when Amazon really made it. **AWS's own record of this image maps an 8 GiB `gp3`
root that is deleted with the instance.** The structure is the one AWS returns; the values in it
are moto's.

## Finding the current one: the public parameter

An AMI id changes every time its publisher rebuilds it, which for a maintained distribution is every
few weeks, with the latest security fixes. An id written into a template is therefore a copy of a
fact that stops being true. **AWS publishes the current id under a name that does not change**, as
a public parameter of Systems Manager Parameter Store, and anybody can read it:

```
ana@laptop:~/aws$ aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text
ami-0b44997419d0b0d38
```

That name will answer with a different id next month, and that is the point: the parameter moves,
the template that reads it does not. A launch template can name the parameter instead of the id,
with `resolve:ssm:` in front of it, and resolve it at each launch; lesson 4 builds one. moto ships a
copy of these Amazon Linux parameters, which is why the call above answered.

Canonical does the same for Ubuntu, under its own path. moto has no copy of that one:

```
ana@laptop:~/aws$ aws ssm get-parameter --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id

aws: [ERROR]: An error occurred (ParameterNotFound) when calling the GetParameter operation: Parameter /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id not found.
```

**On AWS the same command returns the current Ubuntu 24.04 image for `sa-east-1`.** It was not run
here, and the path is the one Canonical documents for the `amd64` build on a `gp3` root; an `arm64`
build has its own path beside it.

## Finding one by owner and name

Before the parameters existed, the way to find an image was to filter the catalogue by owner and
name and take the newest. It still works on AWS, and it is worth knowing because you will meet it
in old scripts:

```
ana@laptop:~/aws$ aws ec2 describe-images --query "length(Images)"
1155
ana@laptop:~/aws$ aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/*" --query "sort_by(Images,&CreationDate)[].[ImageId,CreationDate,Name]" --output text
ami-1e749f67	2026-10-16T16:25:15.000Z	ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-20170727
ami-785db401	2026-10-16T16:25:15.000Z	ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20170721
```

moto's catalogue holds 1,155 images, and for Canonical's account, `099720109477`, it holds two:
Ubuntu 14.04 and 16.04, built in 2017. Both are moto's fixtures and neither is anything you would
launch today. Look at the dates as well. **Every image moto ships is dated the moment moto
started**, so sorting by `CreationDate`, the idiom's whole trick, sorts nothing here. On AWS the
date is when the image was registered and the sort works.

**Always filter by owner.** A name filter alone matches every public image whose name starts the
same way, and anybody can publish a public image named `ubuntu/images/…` from their own account.
The owner id is what says Canonical made it. The parameter avoids the question altogether, which
is the strongest argument for it.
