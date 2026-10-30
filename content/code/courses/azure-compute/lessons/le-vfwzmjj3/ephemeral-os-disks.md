---
title: Ephemeral OS disks, for machines that keep nothing
version: 1
---

The OS disk sounds like the one disk that must be safe, since the machine cannot boot without it.
For a machine that keeps nothing of its own, that safety is paid for and never used. **An
ephemeral OS disk is written to the host's local storage instead of Azure Storage**. The machine
boots from it and reads and writes it at local speed, and what it wrote is lost when the machine is
moved to another host by a resize, a redeploy or a repair. What
you get in exchange is lower latency on the OS disk and a reimage that is quick, because a fresh
copy of the image is all there is to restore.

## Where it is placed

The disk goes on whichever local storage the size has, and `diffDiskSettings` in the declaration
says which:

| placement | the local storage | sizes that have it |
| --- | --- | --- |
| `CacheDisk` | the host cache of older sizes | Dsv2, Dsv3 |
| `ResourceDisk` | the temporary disk | sizes with one, such as Ddsv5 and Dadsv5 |
| `NvmeDisk` | local NVMe disks | v6 and later, such as Ddsv6 and Dadsv6 |

Microsoft recommends the current series with `ResourceDisk` or `NvmeDisk`. The placement changes
where the disk sits and nothing about its cost or speed, which come from that storage. The image
has to fit: Microsoft gives the Ubuntu Server image as about 30 GiB, so a temporary disk of 30 GiB
or more takes it, and **the temporary disk then shrinks by the size of the image**. A
`Standard_D2ds_v5` has a 75 GiB temporary disk, which leaves 45 once the OS disk is on it. Trusted
Launch reserves 1 GiB more for the machine's guest state. Microsoft quotes the refusal for a
75 GiB image on a `Standard_D2ads_v5`, whose temporary disk is also 75 GiB: *OS disk of Ephemeral
VM with size greater than 74 GB is not allowed*.

By default the disk is **partially cached**: the writes go to the host and the image's original
blocks are read from a managed disk behind it, whose type you choose: Standard HDD, Standard SSD or
Premium SSD. **Full caching** puts the whole OS disk on the host, so the machine no longer needs
remote storage once it is running. It takes twice the OS disk's size plus 1 GiB of local storage,
and Microsoft offers it only on sizes of eight vCPUs or more.

## What you give up

Microsoft's comparison, with the rows that decide whether a machine can have one:

| | persistent OS disk | ephemeral OS disk |
| --- | --- | --- |
| stop and deallocate | supported | **not supported** |
| resize to another size | OS disk kept | OS disk deleted, OS provisioned again |
| redeploy to another host | OS disk kept | OS disk deleted, OS provisioned again |
| a host failure that Azure heals | OS disk kept | **not kept** |
| live migration during maintenance | OS disk kept | kept |
| resize the OS disk | at creation, or deallocated | at creation only |

**There is no stop-deallocate**, which is the row that surprises people: a machine with an
ephemeral OS disk that is not wanted tonight is deleted, not stopped, and created again tomorrow.
Microsoft's frequently asked questions say the same for Spot machines, lesson 5. The disk also
cannot be snapshotted or captured as an image, and Azure Backup, Azure Site Recovery and Azure Disk
Encryption do not apply to it. Data disks still can: a machine with an ephemeral OS disk may have
managed data disks attached, and they behave exactly as in the first section.

## Why a scale set wants them

Picture the shop's order API on six web servers behind a load balancer. Every byte on their OS
disks came from the image of lesson 2 and its cloud-init file; the orders live in the database, and
the logs are sent elsewhere. A web server that fails is replaced, not repaired. **For a machine
like that, a persistent OS disk is a copy nobody will ever read**, and reimaging it from the image
is the repair. Lesson 4's scale sets do exactly that, replacing or reimaging an instance as the
normal way of dealing with one, and they create many at once, where a faster deployment adds up.

The shop's database is the opposite case, and keeps the persistent disks of the first section.

## Declaring one

The web server of lesson 2, on a size with a temporary disk and with its OS disk made ephemeral.
Save it as `web.bicep`:

```bicep
// web.bicep
param location string = 'brazilsouth'
param adminUsername string = 'ana'
param sshPublicKey string
param nicId string

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-web-1'
  location: location
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ds_v5'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadOnly'
        diffDiskSettings: {
          option: 'Local'
          placement: 'ResourceDisk'
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    osProfile: {
      computerName: 'shop-web-1'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
  }
}
```

Three lines make the difference. `option: 'Local'` is what makes the disk ephemeral, `placement:
'ResourceDisk'` puts it on the temporary disk of the `D2ds_v5`, and the caching is `ReadOnly`,
which Microsoft's deployment guide requires for an ephemeral OS disk. The CLI offers the same
choice as two options of `az vm create`:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-ephemeral-os-disk : [^.]*\.[^-]*"
--ephemeral-os-disk : Allows you to create an OS disk directly on the host node, providing local disk performance and faster VM/VMSS reimage time. Allowed values: false, true. 
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-ephemeral-os-disk-placement --ephemeral-placement : [^.]*\.[^.]*\.[^-]*"
--ephemeral-os-disk-placement --ephemeral-placement : Only applicable when used with `--ephemeral-os- disk`. Allows you to choose the Ephemeral OS disk provisioning location. Allowed values: CacheDisk, NvmeDisk, ResourceDisk. 
```

And the compiler:

```
ana@laptop:~/azure$ bicep build web.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.storageProfile.osDisk" web.json
{
  "createOption": "FromImage",
  "caching": "ReadOnly",
  "diffDiskSettings": {
    "option": "Local",
    "placement": "ResourceDisk"
  }
}
```

Now the two mistakes that matter most here, made together on a copy: `ReadWrite` caching, which
the guide does not allow, and a placement called `TempDisk`, which is how Microsoft's pages name the
placement whose value is `ResourceDisk`:

```
ana@laptop:~/azure$ bicep build web-wrong.bicep
ana@laptop:~/azure$ jq -c ".resources[0].properties.storageProfile.osDisk | {caching, diffDiskSettings}" web-wrong.json
{"caching":"ReadWrite","diffDiskSettings":{"option":"Local","placement":"TempDisk"}}
ana@laptop:~/azure$ grep -n -A1 "placement" web-full.bicep
29:          placement: 'ResourceDisk'
30-          enableFullCaching: true
ana@laptop:~/azure$ bicep build web-full.bicep
/home/ana/azure/web-full.bicep(30,11) : Warning BCP037: The property "enableFullCaching" is not allowed on objects of type "DiffDiskSettings". No other properties are allowed. If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP037]
ana@laptop:~/azure$ bicep build web-full-2504.bicep
/home/ana/azure/web-full-2504.bicep(30,11) : Warning BCP037: The property "enableFullCaching" is not allowed on objects of type "DiffDiskSettings". No other properties are allowed. If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP037]
ana@laptop:~/azure$ bicep build web-full-2511.bicep
```

**Neither was caught.** The placement is a string the compiler checks only for being a string, and
`ReadWrite` is one of the three values it knows; whether an ephemeral OS disk may have it is a rule
of the service. Both went into the template as written, and both are Azure's to judge when the
request arrives.

The last three builds asked for full caching, `enableFullCaching`. On `2024-07-01`, the API version
this course uses for machines, and on `2025-04-01`, the compiler did not know the property; on
`2025-11-01` it compiled cleanly. Microsoft's guide says `2025-04-01` or later, so the compiler's
types and the documentation disagree about one version, which is the kind of case the warning's
sentence about inaccurate type definitions exists for. It does not matter for `shop-web-1`: with two
vCPUs, the `D2ds_v5` is below the eight that full caching needs, and the copies were a test of the
compiler, not a change to the file.
