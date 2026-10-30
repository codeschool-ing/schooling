---
title: Azure Files, one share for many machines
version: 1
---

When the shop's web servers need the same uploaded product photos, the first idea is one managed
disk attached to all of them. Azure does let a disk be attached to several machines at once, but
Microsoft documents that for clusters, with a cluster manager such as Pacemaker or Windows Server
Failover Clustering deciding who may write. An ordinary file system was never built for two
machines writing it at once. **A managed disk is a block device for one machine; Azure Files is a file
share for many.** It is a managed service that serves file shares over SMB and NFS, the two
protocols Windows and Linux already speak, and a machine mounts a share the way it would mount
one from a file server.

## What runs here: nothing of it

Lesson 1's lab has Azurite, Microsoft's storage emulator, and it would be natural to expect file
shares from it. Its own help lists what it serves:

```
ana@laptop:~/azure$ docker run --rm mcr.microsoft.com/azure-storage/azurite:3.37.0 azurite --help | grep -o -- "--[a-z]*Port <n> .*"
--blobPort <n>               Optional. Customize listening port for blob (defaults to 10000)
--queuePort <n>              Optional. Customize listening port for queue (defaults to 10001)
--tablePort <n>              Optional. Customize listening port for table (defaults to 10002)
```

**Blob, queue and table, on ports 10000 to 10002, and no file service.** Azurite does not emulate
Azure Files, so this section is read: the protocols, the tiers and the mount commands come from
Microsoft's documentation, read on 2026-10-30, and the one thing run is the compiler.

## A share, a protocol, a tier

A share lives in one of two places. The classic kind is created inside a **storage account**, the
`Microsoft.Storage` resource that also holds blobs and queues; a newer resource type,
`Microsoft.FileShares`, makes a share a top-level resource with no account around it, so far only
for NFS. This course uses the classic kind, which supports everything.

Each share speaks one protocol, chosen when it is created:

| | SMB | NFS |
| --- | --- | --- |
| clients | Windows, Linux, macOS | Linux |
| version | 3.1.1, 3.0, 2.1 | 4.1 |
| media | SSD or HDD | SSD only |
| redundancy | LRS, ZRS, GRS, GZRS | LRS, ZRS |
| who may connect | an identity, or the account key | the network: a private or service endpoint |
| permissions | Windows ACLs | UNIX permissions |

The media tier is SSD, which the CLI and older pages call *premium*, or HDD, the *standard* tier.
An SSD share needs a storage account of the kind `FileStorage`; an HDD share sits in one too on
provisioned v2, and in an ordinary `StorageV2` account on pay-as-you-go. Those are the three ways
to pay:

- **provisioned v2**, where storage, IOPS and throughput are set apart, like the disks of the last
  section but one; Microsoft recommends it for every new share;
- **provisioned v1**, SSD only, where the IOPS and throughput follow from the size;
- **pay-as-you-go**, HDD only, billed for the bytes stored and for every transaction.

**Provisioned v2 comes with a recommendation**, and on SSD it is arithmetic Microsoft publishes:
3,000 IOPS plus one per GiB provisioned, and 100 MiB/s plus a tenth of a MiB/s per GiB, rounded
up. The smallest share is 32 GiB. A share may be given up to five times the recommendation, or as
little as the minimum, 3,000 IOPS and 100 MiB/s.

## Declaring one

An NFS share for the uploads, 100 GiB on provisioned v2 SSD. Save it as `files.bicep`:

```bicep
// files.bicep
param location string = 'brazilsouth'

resource account 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: 'shopfiles2026'
  location: location
  kind: 'FileStorage'
  sku: {
    name: 'PremiumV2_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
  }
}

resource files 'Microsoft.Storage/storageAccounts/fileServices@2025-01-01' = {
  parent: account
  name: 'default'
}

resource uploads 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-01-01' = {
  parent: files
  name: 'uploads'
  properties: {
    enabledProtocols: 'NFS'
    rootSquash: 'RootSquash'
    shareQuota: 100
    provisionedIops: 3100
    provisionedBandwidthMibps: 110
  }
}
```

`FileStorage` with `PremiumV2_LRS` is how the documentation spells *SSD, provisioned v2, locally
redundant*. The account's name is a host name on the internet, so it has to be unique across all
of Azure, and `shopfiles2026` is only an example. `shareQuota` is the provisioned size in GiB, and
the two numbers below it are the recommendation for 100 GiB: 3,000 + 100 = 3,100 IOPS, and 100 +
10 = 110 MiB/s. `RootSquash` maps the client's root user to an anonymous one on the share, so
that root on a compromised web server cannot rewrite every file; it is not the default for a new
Azure share, which is why it is written.

The CLI's help says which accounts NFS needs:

```
ana@laptop:~/azure$ az storage share-rm create --help | tr -s "[:space:]" " " | grep -o "\-\-enabled-protocols : [^.]*\.[^.]*\.[^-]*"
--enabled-protocols : The authentication protocol that is used for the file share. NFS protocol will be only available for premium file shares (file shares in the FileStorage account type). Can only be specified when creating a share. Allowed values: NFS, SMB. 
```

And the compiler takes all three resources:

```
ana@laptop:~/azure$ bicep build files.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, kind, sku: .sku.name}" files.json
{"type":"Microsoft.Storage/storageAccounts","kind":"FileStorage","sku":"PremiumV2_LRS"}
{"type":"Microsoft.Storage/storageAccounts/fileServices","kind":null,"sku":null}
{"type":"Microsoft.Storage/storageAccounts/fileServices/shares","kind":null,"sku":null}
ana@laptop:~/azure$ jq ".resources[2].properties" files.json
{
  "enabledProtocols": "NFS",
  "rootSquash": "RootSquash",
  "shareQuota": 100,
  "provisionedIops": 3100,
  "provisionedBandwidthMibps": 110
}
```

As for the disks, the protocol is a string to it:

```
ana@laptop:~/azure$ bicep build files-proto.bicep
ana@laptop:~/azure$ jq -r ".resources[2].properties.enabledProtocols" files-proto.json
NFSv4
```

`NFSv4` reached the template, and Azure would refuse it. So would `NFS` on an HDD account, which
the help text above rules out and the compiler has no way to see.

## Reaching it

**NFS has no user sign-in**, so the network is the authentication. The share is reachable only
through a private endpoint, an address in the virtual network of `azure-foundations` lesson 16, or
through a service endpoint on the client's subnet. This file switches the public endpoint off and
declares no private endpoint, which is a resource of its own: deployed as it stands, the share
would be reachable by nobody.

On a Linux machine with a route to it, Microsoft's guide installs its mount helper, `aznfs`, from
Microsoft's package repository, and mounts with encryption in transit:

```sh
sudo mkdir -p /mnt/uploads
sudo mount -t aznfs \
    shopfiles2026.file.core.windows.net:/shopfiles2026/uploads \
    /mnt/uploads \
    -o vers=4,minorversion=1,sec=sys,nconnect=4
```

**SMB** uses TCP port 445, which many networks and internet providers block on the way out. On
Linux it needs the `cifs-utils` package, a credentials file only root can read, and `mount -t
cifs`. Microsoft recommends signing in with an identity rather than the account key, because a
share mounted with the key gives full permission on every file and folder, whatever their ACLs
say.

Neither command was run: there is no share to mount, and nothing on this laptop pretends to be
one.

## What it is for, and what it is not

It fits **files that several machines read and write**. For the shop, that is the uploaded
photos, served by every web server, and the nightly sales report, written by one machine and
picked up by the finance export on another. Elsewhere it is a team's shared tools, or the
persistent volume of a container that may run
on any node, in Container Apps or in AKS. Snapshots of a share are incremental, up to 200 per
share.

It fits a database badly. Every operation crosses the network to a storage service, and a
database's log waits on exactly that latency. The database keeps the managed disks of the first
two sections, and the share holds what is shared.
