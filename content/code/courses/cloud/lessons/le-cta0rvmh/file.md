---
title: "File storage: one filesystem, many machines"
version: 1
---

A managed file service is **a network filesystem somebody else runs**: EFS on AWS, Azure Files,
Filestore on Google Cloud. Machines mount it with the client their operating system already has,
NFS on Linux and SMB on Windows. Azure Files speaks both, EFS speaks NFS. Once mounted it is a
directory like any other, and nothing in the program using it has to know it is on the network.
On AWS the mount is one line, written here for the lesson and not run, since there is no account:

```sh
sudo mount -t nfs4 -o nfsvers=4.1 fs-0123456789abcdef0.efs.sa-east-1.amazonaws.com:/ /shared
```

What it gives you that a volume cannot is **several machines reading and writing the same files at
once**, with the service keeping the filesystem consistent. Two web servers behind a load balancer
both see the image a user uploaded through either of them. EFS keeps its data in several zones of
the region, so instances in different zones mount the same filesystem. It grows and shrinks with
what is stored, so there is no size to pick, and **it is billed on the gigabytes actually stored**,
which is the opposite of a volume.

## When it is the right tool

A program written for a shared directory. A lot of software was: a content management system that
writes uploads to `wp-content/uploads`, two legacy applications that exchange files through a
directory one writes and the other polls, a build farm sharing a cache, home directories for a
group of Linux users. Rewriting any of them to speak to an object store is real work, and a file
service lets them move to a cloud unchanged.

::: track devops devsecops
The `kubernetes` course met this split under other names. A PersistentVolumeClaim asking for
`ReadWriteOnce` is usually served by a block volume, and one asking for `ReadWriteMany` needs a file
service behind it, because only a filesystem somebody runs for you can be written by pods on
several nodes at once.
:::

::: track *
Container platforms meet the same split under other names. Storage that one node writes is usually
a block volume, and storage that pods on several nodes write at once needs a file service behind it,
because a block volume is attached to one machine.
:::

## What it costs

**The price is the other half of the answer.** EFS Standard is 0.5700 USD per GB-month in
`sa-east-1`, against 0.1520 for a `gp3` volume, and the next section puts the two lines side by side.
Some of the difference is the replication across zones and some is the service running the
filesystem for you. EFS has cheaper tiers for files nobody opens often, which the course's sheet
does not carry; the vendor course does.

It also brings the habits of every network filesystem. **Each file operation is a round trip over
the network**, so work that touches thousands of small files, such as `npm install` or a Git
checkout, runs far slower there than on a volume. Locking works and costs a round trip too. And a
shared directory is shared state: two machines writing the same file at the same moment still need
the application to decide which write wins.
