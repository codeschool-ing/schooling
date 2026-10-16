---
title: Building an image of your own
version: 1
---

Building an image sounds like a special kind of work, with tools of its own. **An image of your own
is an instance you configured, saved.** You launch one from a published image, install and
configure what every machine needs, and ask EC2 to turn its disks into a new AMI. Every tool that
builds images, from a console button to Packer, runs those same three steps.

## The three steps

From the Amazon Linux 2023 image the parameter names, one small instance:

```
ana@laptop:~/aws$ BASE=$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text)
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id "$BASE" --instance-type t3.micro --query "Instances[0].InstanceId" --output text)
```

**This is where the work would go**, and it is the one step this lesson cannot run. On AWS you
would connect to the instance, or give it user data, and install the software: `sudo dnf install
-y nginx`, the configuration, the application at a known version. moto starts no machine, so there
is nothing to connect to and nothing gets installed; lesson 7 is about user data, the scripted way
to do this step. The image below is made from an instance that holds exactly what its base image
held, and its description is a label we chose.

Then the image itself:

```
ana@laptop:~/aws$ IMG=$(aws ec2 create-image --instance-id "$ID" --name web-2026-10-16 --description "nginx on Amazon Linux 2023" --tag-specifications "ResourceType=image,Tags=[{Key=app,Value=web}]" --query ImageId --output text)
ana@laptop:~/aws$ aws ec2 describe-images --owners self
{
    "Images": [
        {
            "BlockDeviceMappings": [
                {
                    "Ebs": {
                        "DeleteOnTermination": false,
                        "SnapshotId": "snap-ea6b97d76b42a5e1a",
                        "VolumeSize": 15,
                        "VolumeType": "standard"
                    },
                    "DeviceName": "/dev/sda1"
                }
            ],
            "Description": "nginx on Amazon Linux 2023",
            "Name": "web-2026-10-16",
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "standard",
            "Tags": [
                {
                    "Key": "app",
                    "Value": "web"
                }
            ],
            "VirtualizationType": "hvm",
            "BootMode": "uefi",
            "SourceInstanceId": "i-52f3615249060ee52",
            "ImageId": "ami-a9a13e442ffd8c0ff",
            "State": "available",
            "OwnerId": "123456789012",
            "CreationDate": "2026-10-16T16:25:26.000Z",
            "Public": false,
            "ProductCodes": [],
            "Architecture": "x86_64",
            "ImageType": "machine"
        }
    ]
}
```

`create-image` returned an AMI id, kept here in `IMG`, and the record has the same shape as
Amazon's: `OwnerId` is now moto's account, `123456789012`, `Public` is `false`, and
`SourceInstanceId` names the instance it was made from. The tag was applied to the image as it was
created, which is the way to give an image its version and owner from the start. moto has also
renamed the root device to `/dev/sda1`, where the base image said `/dev/xvda`, which is a detail of
its own rather than AWS's.

**By default, `create-image` reboots the instance first**, so that everything the operating system
held in memory is written out and the snapshot is of a file system at rest. `--no-reboot` skips
that, and the image then has the consistency of a power cut, as the previous section said of any
snapshot. It is the right flag only for a machine you cannot afford to reboot and whose disk is not
being written.

## What the image is made of

The mapping names a snapshot, and the snapshot says where it came from:

```
ana@laptop:~/aws$ SNAP=$(aws ec2 describe-images --image-ids "$IMG" --query "Images[0].BlockDeviceMappings[0].Ebs.SnapshotId" --output text)
ana@laptop:~/aws$ aws ec2 describe-snapshots --snapshot-ids "$SNAP" --query "Snapshots[].[SnapshotId,VolumeSize,Description]" --output text
snap-ea6b97d76b42a5e1a	15	Created by CreateImage(i-52f3615249060ee52) for ami-a9a13e442ffd8c0ff
```

EC2 took a snapshot of each volume in the instance and wrote the AMI's id into the description, so
a snapshot found on its own later can be traced back to the image that owns it. That snapshot is
what you pay for while the image exists.

## Launching from it

The new id launches like any other, and every machine launched from it starts with the same bytes:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id "$IMG" --instance-type t3.micro --count 2 --query "Instances[].[InstanceId,ImageId]" --output text
i-ec83a4a0f45b85084	ami-a9a13e442ffd8c0ff
i-c8ee5215dcef0048f	ami-a9a13e442ffd8c0ff
```

**That sameness is what an image is for.** Two machines launched from it a month apart are
identical, where two machines that installed their software at boot get whatever the package
mirrors held on each day. An image does not change after it is made; a fix is a new image with a
new id, and the machines move to it by being replaced, which lesson 4's instance refresh does for a
whole group.

## Baking or configuring at boot

Every piece of software a machine needs can go into the image or be installed when the machine
starts. The trade, in short:

| | in the image | at first boot |
|---|---|---|
| time from launch to serving | the boot | the boot and every install |
| depends on, at launch | nothing outside the instance | package mirrors, downloads |
| two launches a month apart | the same bytes | whatever was current each day |
| a security fix | a new image, then replace the machines | the next launch picks it up |

The usual answer is both: **bake what is slow to install and changes rarely**, the runtime, the
packages and the application at a version. Configure at boot what differs per machine or must not
be written into an image, such as the environment it belongs to or a secret fetched at start.
A secret baked into an image is in every snapshot of it and in every account the image is shared
with, which is the next section.

## The tools that do this for you

Done by hand, the three steps are a checklist somebody forgets a line of. Two tools run them the
same way every time:

- **EC2 Image Builder** is AWS's managed service. A *recipe* names the base image and the
  *components*, each a document of build steps; a *pipeline* runs the recipe on a schedule or on
  demand, tests the result, and distributes the AMI to the regions and accounts it names. It
  charges nothing itself; you pay for the instances and snapshots it uses. It was not run here,
  because moto does not implement it.
- **Packer**, from HashiCorp, works across clouds, and the `iac` course's lesson 20 builds an
  image with it. Its `amazon-ebs` builder launches an instance, runs your provisioners over SSH,
  calls `create-image` and terminates the instance: the steps above, in a file under version
  control.

Whichever builds it, name images so a person can sort them: the application and the date, as
`web-2026-10-16` does here, with the version and the build in tags. Lesson 4's launch template is
where a name like that gets chosen for a group of machines.
