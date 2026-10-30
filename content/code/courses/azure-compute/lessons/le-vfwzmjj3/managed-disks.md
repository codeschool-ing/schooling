---
title: A disk is a resource of its own
version: 1
---

On a laptop the disk is inside the machine, and it is easy to picture an Azure virtual machine the
same way. **A managed disk is a resource of its own, beside the virtual machine and not inside
it.** It has a name, a type, a size and a line on the bill of its own, and it lives in Azure
Storage, reached over the network. The machine is attached to its disks the way it is attached to
its network interface, and a disk can outlive the machine, move to another one, or be copied while
the machine carries on. Microsoft describes it as a block-level volume where you choose the type
and the size and Azure does the rest.

## Three roles, and one of them is not a managed disk

Every machine has an **OS disk**, made from the image when the machine is created, which lesson 2
was about. It holds the boot volume and can be up to 4,095 GiB, although an image partitioned with
a master boot record, as many are, can use only 2 TiB of it.

**Data disks** are the ones you add, and the size decides how many: lesson 1's table gave a
`Standard_D2s_v5` four and a `Standard_D8s_v5` sixteen. Each is attached at a *LUN*, a logical
unit number from 0 upwards, which is how the operating system and the declaration both tell them
apart. Microsoft's advice is to keep the application and its data on data disks and the operating
system alone on the OS disk, so that each can be backed up, resized and replaced on its own.

The third is the **temporary disk**, which the sizes with a `d` in their name carry. It is not a
managed disk. It sits on the host the machine runs on, appears on Linux as
`/dev/disk/azure/resource`, and survives an ordinary restart. Microsoft's documentation says its
data may be lost during a maintenance event, when the machine is redeployed, or when it is stopped,
and that it is meant for page files, swap and the scratch files of a database such as SQL Server's
`tempdb`.

```schooling-figure
{"svg": "<svg id=\"fig-disk-roles\" viewBox=\"0 0 720 332\" role=\"img\" aria-label=\"Two boxes side by side. On the left, the host the machine runs on: the virtual machine, a host cache made of memory and local SSD, and the temporary disk, /dev/disk/azure/resource. On the right, Azure Storage, reached over the network: the log disk at LUN 1 with caching None, reached directly from the machine; the OS disk with caching ReadWrite and the data disk at LUN 0 with caching ReadOnly, both reached through the host cache. Each managed disk is three copies. A note below: after a deallocation the machine may return on another host, where the temporary disk can be empty and the managed disks are unchanged.\"><defs><marker id=\"disks-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"12\" width=\"330\" height=\"252\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the host the machine runs on</text><rect x=\"32\" y=\"44\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"177\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">the virtual machine</text><rect x=\"110\" y=\"122\" width=\"212\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">host cache: memory and local SSD</text><rect x=\"32\" y=\"196\" width=\"290\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">temporary disk</text><text x=\"177\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/dev/disk/azure/resource</text><line x1=\"177\" y1=\"88\" x2=\"177\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><line x1=\"60\" y1=\"88\" x2=\"60\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><rect x=\"378\" y=\"12\" width=\"330\" height=\"252\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"392\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Azure Storage, over the network</text><rect x=\"398\" y=\"44\" width=\"290\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"543\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">log disk, LUN 1</text><text x=\"543\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">caching: None</text><rect x=\"398\" y=\"104\" width=\"290\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"543\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">OS disk</text><text x=\"543\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">caching: ReadWrite</text><rect x=\"398\" y=\"164\" width=\"290\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"543\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">data disk, LUN 0</text><text x=\"543\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">caching: ReadOnly</text><text x=\"543\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each managed disk is three copies, LRS or ZRS</text><line x1=\"322\" y1=\"66\" x2=\"396\" y2=\"66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><line x1=\"322\" y1=\"136\" x2=\"396\" y2=\"129\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><line x1=\"322\" y1=\"152\" x2=\"396\" y2=\"189\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><rect x=\"12\" y=\"280\" width=\"696\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Deallocated, the machine may return on another host: an empty temporary disk, the same managed disks.</text></svg>", "caption": "What is on the left is the host's, and stays behind when the machine moves; what is on the right is reached over the network from wherever the machine runs. The caching value of each disk decides whether its operations pass through the host on the way."}
```

## Three copies, in one datacentre or across three zones

A managed disk is three copies, and the redundancy option says where they are. **LRS**, locally
redundant storage, writes all three synchronously in one datacentre, which Microsoft rates at
eleven nines of durability a year. **ZRS**, zone-redundant storage, writes them to three
availability zones of the region and is rated at twelve nines; its writes take longer, because they
cross zones, and Microsoft offers it only on Premium SSD and Standard SSD. Lesson 6 is about zones.

Neither is a backup. A file deleted by mistake is deleted from all three copies in the same
instant, and that is what snapshots, at the end of this section, are for.

## Declaring two disks and attaching them

The shop's order database would want two data disks: one for its data files and one for its write
log, which databases keep apart because the two are used in opposite ways. Save this as
`db.bicep`. The network interface and the key are parameters, as in lesson 2:

```bicep
// db.bicep
param location string = 'brazilsouth'
param adminUsername string = 'ana'
param sshPublicKey string
param nicId string

resource data 'Microsoft.Compute/disks@2024-03-02' = {
  name: 'shop-db-data'
  location: location
  zones: [
    '1'
  ]
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 1024
  }
}

resource log 'Microsoft.Compute/disks@2024-03-02' = {
  name: 'shop-db-log'
  location: location
  zones: [
    '1'
  ]
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 128
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-db-1'
  location: location
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4ds_v5'
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
        caching: 'ReadWrite'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Attach'
          caching: 'ReadOnly'
          deleteOption: 'Detach'
          managedDisk: {
            id: data.id
          }
        }
        {
          lun: 1
          createOption: 'Attach'
          caching: 'None'
          deleteOption: 'Detach'
          managedDisk: {
            id: log.id
          }
        }
      ]
    }
    osProfile: {
      computerName: 'shop-db-1'
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

The two disks are resources declared before the machine, created `Empty`, and the machine names
them by `data.id` and `log.id`. Their sizes are not arbitrary: Premium SSD is sold in tiers, and
1,024 GiB and 128 GiB are exactly the tiers called P30 and P10, which the next section gives
numbers to. The `deleteOption` on each says what deleting the machine does to it. It is written
out because the defaults differ by tool: Microsoft's documentation says the CLI detaches the OS
disk when the machine is deleted, and the portal deletes it. **A detached disk is still billed**,
every hour, attached to nothing. Here the OS disk goes with the machine and the two data disks
stay, because they hold the orders.

The values the CLI offers for the two disk settings, without an account:

```
ana@laptop:~/azure$ az disk create --help | tr -s "[:space:]" " " | grep -o "\-\-sku : [^.]*\. Allowed values: [A-Za-z0-9_, ]*"
--sku : Underlying storage SKU. Allowed values: PremiumV2_LRS, Premium_LRS, Premium_ZRS, StandardSSD_LRS, StandardSSD_ZRS, Standard_LRS, UltraSSD_LRS
ana@laptop:~/azure$ az vm disk attach --help | tr -s "[:space:]" " " | grep -o "\-\-caching : [^.]*\. Allowed values: [A-Za-z, ]*"
--caching : Disk caching policy. Allowed values: None, ReadOnly, ReadWrite
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-os-disk-caching : [^.]*\. Default: [A-Za-z]*\. Allowed values: [A-Za-z, ]*"
--os-disk-caching : Storage caching type for the VM OS disk. Default: ReadWrite. Allowed values: None, ReadOnly, ReadWrite
```

Seven SKUs, and the redundancy is part of the name: `Premium_ZRS` is Premium SSD with zone
redundancy. Compile the file:

```
ana@laptop:~/azure$ bicep build db.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, name, zones, sku: .sku.name, size: .properties.diskSizeGB}" db.json
{"type":"Microsoft.Compute/disks","name":"shop-db-data","zones":["1"],"sku":"Premium_LRS","size":1024}
{"type":"Microsoft.Compute/disks","name":"shop-db-log","zones":["1"],"sku":"Premium_LRS","size":128}
{"type":"Microsoft.Compute/virtualMachines","name":"shop-db-1","zones":["1"],"sku":null,"size":null}
ana@laptop:~/azure$ jq ".resources[2].properties.storageProfile.dataDisks" db.json
[
  {
    "lun": 0,
    "createOption": "Attach",
    "caching": "ReadOnly",
    "deleteOption": "Detach",
    "managedDisk": {
      "id": "[resourceId('Microsoft.Compute/disks', 'shop-db-data')]"
    }
  },
  {
    "lun": 1,
    "createOption": "Attach",
    "caching": "None",
    "deleteOption": "Detach",
    "managedDisk": {
      "id": "[resourceId('Microsoft.Compute/disks', 'shop-db-log')]"
    }
  }
]
ana@laptop:~/azure$ jq -c ".resources[2].dependsOn" db.json
["[resourceId('Microsoft.Compute/disks', 'shop-db-data')]","[resourceId('Microsoft.Compute/disks', 'shop-db-log')]"]
```

No warnings. Bicep saw `data.id` and `log.id` and wrote a `dependsOn` for the machine on both
disks into the template, so Resource Manager creates the disks first.

## Host caching, chosen per disk

Each attachment carries a `caching` value, and it decides whether the host the machine runs on
keeps a copy of the disk's blocks in its own memory and local SSD. **`ReadOnly` serves repeated
reads from the host**, and reads served from the cache do not count against the disk's limits;
writes go through to the disk as before. **`ReadWrite` also holds writes on the host** and writes
them to the disk later. That is fast, and safe only for software that flushes what it must keep,
such as SQL Server; anything else can lose the writes still in the cache if the machine crashes.
**`None`** sends every operation to the disk.

Microsoft's guidance for a database is the pair in the file: `ReadOnly` on the disk holding the
data files, which are read far more than written, and `None` on the log, which is written in order
and almost never read. The OS disk defaults to `ReadWrite`, and `None` is not accepted there. For
data disks, two of Microsoft's pages disagree about the default, one saying `ReadOnly` and the
other no caching, which is a good reason to write it every time. Two more facts belong here:
caching is not available on a disk of 4 TiB or more, and changing a disk's caching detaches and
reattaches it, which on the OS disk restarts the machine.

The compiler knows the three values exactly, and refuses a fourth:

```
ana@laptop:~/azure$ bicep build db-typo.bicep
/home/ana/azure/db-typo.bicep(79,20) : Warning BCP036: The property "caching" expected a value of type "'None' | 'ReadOnly' | 'ReadWrite' | null" but the provided value is of type "'none'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
ana@laptop:~/azure$ bicep build db-zone.bicep
ana@laptop:~/azure$ jq -c ".resources[] | [.name, .zones]" db-zone.json
["shop-db-data",["2"]]
["shop-db-log",["1"]]
["shop-db-1",["1"]]
```

The misspelt `none` was caught. The second copy moved the data disk to zone 2 and left the machine
in zone 1, and that compiled cleanly. An LRS disk lives in one zone, and Microsoft documents
attaching a disk to machines in another zone only for ZRS disks; **that mismatch is Azure's to
refuse, and the compiler cannot see it.**

## Detaching, and snapshots

Moving a data disk to another machine is done in that order: inside the machine, unmount the file
system and remove its line from `/etc/fstab`, where Microsoft's guide names it by UUID with the
`nofail` option; then `az vm disk detach`; then attach it elsewhere in the same zone. The commands
need a subscription and were not run here.

A **snapshot** is a read-only, crash-consistent copy of one disk at one moment, kept as a resource
of its own and used to create new disks. A full snapshot copies the whole disk. An **incremental**
snapshot stores only what changed since the previous one, the first being a full copy. Microsoft
keeps incremental snapshots on Standard HDD, on ZRS where the region has it, and bills them for
the space used:

```
ana@laptop:~/azure$ az snapshot create --help | tr -s "[:space:]" " " | grep -o "\-\-incremental : [^.]*\.[^-]*"
--incremental : Whether a snapshot is incremental. Incremental snapshots on the same disk occupy less space than full snapshots and can be diffed. Allowed values: false, true. 
```

One limit matters for the database above. A snapshot covers one disk, and two snapshots of two
disks are not taken at the same instant, so the data and the log are not guaranteed to agree with
each other. Microsoft's answer for several disks at once is a *restore point* of the machine,
which captures all of its disks in a consistent order; it too needs a subscription.
