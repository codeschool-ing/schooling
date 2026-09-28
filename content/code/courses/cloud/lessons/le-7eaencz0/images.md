---
title: "Images: the disk an instance starts from"
version: 1
---

An image is often described as "the operating system you pick", as if it were a menu choice like
the instance type. **An image is a disk.** More precisely, it is a template for a boot disk: the
operating system, and whatever else was installed and configured on it when the image was made.
Launching an instance copies that template onto a new disk and boots from it. AWS calls one an AMI,
an Amazon Machine Image; the other providers say image.

## Where images come from

**Published images** are made by whoever makes the operating system. Canonical publishes Ubuntu,
Debian publishes Debian, AWS publishes Amazon Linux, and each keeps releasing new builds of the
same version with the latest security fixes. These are the starting point for almost everybody,
and they contain almost nothing: the system, the cloud agent that reads user data, and an SSH
server.

**Your own images** start from one of those. You launch it, install your runtime, your
dependencies, your configuration and sometimes the application itself, and save the disk as a new
image. An image made that way and used as the standard starting point for a team's machines is
called a **golden image**. Making one by hand works once; teams build them with a tool that runs
the same steps every time, and Packer is the usual one. The `iac` course builds images that way.

An image lives in one region, and its id is only meaningful there. The same Ubuntu release has one
id in `sa-east-1` and another in `us-east-1`, and a golden image made in São Paulo has to be copied
before anything in N. Virginia can use it. It is also stored, and storage is billed: on AWS an
image is kept as disk snapshots, at 0.0680 USD per GB-month in `sa-east-1` on the sheet. A 20 GB
image stored whole is at most 1.36 USD a month; snapshots keep only the blocks that were written,
so it is often less, and it adds up when every build is kept forever.

## Bake it in, or install it at boot

Every machine needs the same software on it, and there are two places to put that work. You can
**bake** it into the image, so that the instance boots ready. Or you can start from a published
image and **configure at boot**, with user data that installs and sets up everything on the first
start. The trade has two sides, and both matter once there is more than one machine.

| | bake into the image | configure at boot |
|---|---|---|
| time from launch to serving | the boot itself | the boot plus every install, often minutes |
| depends at boot on | nothing outside the instance | package mirrors and downloads being reachable |
| two machines launched a week apart | the same bytes | whatever the mirrors held on each day |
| a security fix | a new image, then replace the machines | the next machine picks it up |

The third row is **drift**: machines that were meant to be the same and are not. A configuration
that runs `apt install nginx` at boot gets the version of `nginx` the mirror has that day, so a
group that grew over a month can hold three versions of it without anybody having decided that.
A baked image cannot drift, because its bytes were fixed when it was built. It ages instead, and
the only cure is to rebuild it and replace every machine running the old one.

The second row matters the day it fails. A machine that installs its software at boot needs the
package mirrors to answer at that moment, and a new machine is launched precisely when something
is under strain: a traffic spike, a failed zone. A machine from a baked image needs nothing
outside itself to start serving.

Most teams settle in between. **Bake what is slow and stable**, the runtime, the packages, the
application at a known version. **Configure at boot what differs per machine**, the hostname,
which environment it belongs to, a secret fetched from the provider's secret store rather than
written into the image. The first row is why this matters for the rest of this lesson: when
autoscaling asks for a new machine, the minutes between launch and serving are minutes of
overload, and the image is where most of them are won or lost.
