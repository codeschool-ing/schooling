---
title: What an AMI is, and how to find the right one
version: 1
---

An AMI is usually pictured as a file, a disk image somebody uploaded, the way an ISO is a file. **An
AMI is a record that points at snapshots.** The record says what the machine needs to boot: the
processor architecture, how it boots, which device is the root disk. The snapshots hold the bytes.
Launching an instance reads the record, makes a new EBS volume from each snapshot it names, and
boots from the root one.

```schooling-figure
{"svg": "<svg id=\"fig-ami-anatomy\" viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Inside the region sa-east-1, an AMI is a record: architecture x86_64, boot mode uefi, root device /dev/xvda and a block device mapping. The mapping names a snapshot, which holds the blocks of the root disk. A launch makes an EBS volume from the snapshot inside one zone, sa-east-1a, and the instance boots from that volume.\"><defs><marker id=\"ami-anatomy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"688\" height=\"262\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">sa-east-1, the region</text><rect x=\"36\" y=\"56\" width=\"220\" height=\"156\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"146\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">the AMI, a record</text><text x=\"50\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Architecture: x86_64</text><text x=\"50\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BootMode: uefi</text><text x=\"50\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RootDeviceName: /dev/xvda</text><text x=\"50\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BlockDeviceMappings:</text><text x=\"50\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">  SnapshotId: snap-…</text><line x1=\"256\" y1=\"160\" x2=\"298\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ami-anatomy-ah)\"></line><text x=\"277\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">names</text><rect x=\"300\" y=\"126\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"375\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">snapshot</text><text x=\"375\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the root disk's blocks</text><text x=\"375\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a launch makes a volume</text><text x=\"375\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">from it, in one zone</text><rect x=\"478\" y=\"46\" width=\"210\" height=\"214\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"490\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1a, one zone</text><rect x=\"498\" y=\"82\" width=\"170\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"583\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">EBS volume</text><text x=\"583\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">made from the snapshot</text><line x1=\"450\" y1=\"160\" x2=\"496\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ami-anatomy-ah)\"></line><line x1=\"583\" y1=\"140\" x2=\"583\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ami-anatomy-ah)\"></line><text x=\"592\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the root</text><rect x=\"498\" y=\"186\" width=\"170\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"583\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">instance</text><text x=\"583\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">boots from that volume</text></svg>", "caption": "An AMI holds no bytes of its own. It describes the machine and names the snapshots; a launch turns each snapshot into a volume in the zone it chose."}
```

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
