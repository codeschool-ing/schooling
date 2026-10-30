---
title: Five disk types, and what each one sells
version: 1
---

It is tempting to read the disk types as a quality ladder, where a better disk is the same thing
made faster. **What separates them is how performance is sold.** Standard HDD, Standard SSD and
Premium SSD come in size tiers, and each tier has its IOPS and throughput fixed: to get more, you
buy a bigger tier. Premium SSD v2 and Ultra Disk sell the three numbers separately, the GiB, the
IOPS and the MB/s, and each can be changed on its own. Whichever you choose, the machine it is
attached to has a ceiling of its own, and the program gets the lower of the two.

## The five

Microsoft's comparison table, read on 2026-10-30:

| | Ultra Disk | Premium SSD v2 | Premium SSD | Standard SSD | Standard HDD |
| --- | --- | --- | --- | --- | --- |
| sold as | three numbers | three numbers | size tiers | size tiers | size tiers |
| largest disk | 65,536 GiB | 65,536 GiB | 32,767 GiB | 32,767 GiB | 32,767 GiB |
| most IOPS | 400,000 | 80,000 | 20,000 | 6,000 | 2,000 |
| most MB/s | 10,000 | 2,000 | 900 | 750 | 500 |
| OS disk | no | no | yes | yes | until 8 September 2028 |
| SKU name | `UltraSSD_LRS` | `PremiumV2_LRS` | `Premium_LRS` | `StandardSSD_LRS` | `Standard_LRS` |

Standard HDD is for backups and data read rarely, and Microsoft is retiring it as an OS disk on
the date in the table. Standard SSD is for web servers, light applications and test machines.
Premium SSD is for production work that needs low latency, and it is what the shop's database
used in the last section. The other two are for databases that need a rate the tiers do not give, and both
are data disks only.

## Premium SSD: the tier decides

A Premium SSD of a given size is a tier with a letter and a number, and the tier fixes its rates.
These are the tiers Microsoft's pages give numbers for:

| tier | size | IOPS | MB/s |
| --- | --- | --- | --- |
| P4 | 32 GiB | 120 | 25 |
| P10 | 128 GiB | 500 | 100 |
| P30 | 1 TiB | 5,000 | 200 |
| P50 | 4 TiB | 7,500 | 250 |

A size between tiers is billed as the next one up: Microsoft's example is a 200 GiB Standard SSD
billed as E15, 256 GiB. So `shop-db-log`, at 128 GiB, gets 500 IOPS. If the log needed 2,000, the
old answer was a disk four times larger than the log needs. **A Premium SSD can also be given a
higher performance tier without growing**: a P10 set to the P50 tier has 7,500 IOPS and 250 MB/s
at 128 GiB, and is billed at the P50 rate until it is set back.

## Bursting, two ways

Premium SSD and Standard SSD can also run above their tier for a while, which is called bursting,
and there are two models.

**Credit-based bursting** is on by default for Premium SSDs up to 512 GiB (P20 and smaller) and
Standard SSDs up to 1,024 GiB, and costs nothing. A disk banks credits while it runs below its
tier and spends them above it, and a full bucket lasts 30 minutes at the highest burst rate,
restocking in less than a day. Microsoft's example is the P4, which it names as the default OS
disk of sizes that take Premium SSD: 120 IOPS and 25 MB/s, bursting to 3,500 and 170, which is why
a machine boots faster than its OS disk's tier suggests. Microsoft also calls the model best effort, so it is not a rate to plan on.

**On-demand bursting** is for Premium SSDs larger than 512 GiB, is off until you enable it, and is
billed: an hourly fee while it is enabled, plus every operation above the tier. A P30 with it
enabled may go from 5,000 IOPS to 30,000, and from 200 MB/s to 1,000. Microsoft's worked example
is a batch job running the P30 at 7,000 IOPS for 60 seconds: (7,000 − 5,000) × 60 = 120,000
operations above the tier, billed as 12 units of 10,000. A disk that is in burst most of the day
belongs in a higher tier, and the documentation says so.

## Premium SSD v2: three numbers

Premium SSD v2 has no tiers. It is any size from 1 GiB to 64 TiB, in steps of one, and **its IOPS
and throughput are set apart from its size**, within limits that grow with it:

- every disk has 3,000 IOPS and 125 MB/s free of charge, and what you set above those is billed;
- from 6 GiB upwards, the most IOPS it may have grows by 500 per GiB, up to 80,000, so a 10 GiB
  disk may have 5,000 and a disk needs 160 GiB to have 80,000;
- the most throughput it may have is 0.25 MB/s for each IOPS set, up to 2,000 MB/s.

Performance can be changed four times in 24 hours, and creating the disk counts as the first.
Three limits come with it: it cannot be an OS disk, it takes **no host caching**, so its
attachment says `None`, and in most regions with zones it attaches only to a machine in a zone.
Brazil South is in Microsoft's list of regions that support it in zones. The CLI's list of SKUs in
the last section had `PremiumV2_LRS` and no `PremiumV2_ZRS`, and that is not an omission: ZRS is
not offered for it.

Ultra Disk takes the same idea further, to 1,000 IOPS per GiB, 400,000 per disk and 10,000 MB/s,
and it is created empty, as a data disk, for workloads such as SAP HANA.

Here is the data disk of the shop's database on Premium SSD v2, with the rates the next part of
this section arrives at. Save it as `disk.bicep`:

```bicep
// disk.bicep
param location string = 'brazilsouth'

resource data 'Microsoft.Compute/disks@2024-03-02' = {
  name: 'shop-db-data'
  location: location
  zones: [
    '1'
  ]
  sku: {
    name: 'PremiumV2_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 256
    diskIOPSReadWrite: 5000
    diskMBpsReadWrite: 145
  }
}
```

The CLI's help for the two properties is behind the service it describes:

```
ana@laptop:~/azure$ az disk create --help | tr -s "[:space:]" " " | grep -o "\-\-disk-[a-z]*-read-write : [^.]*\.[^.]*\."
--disk-iops-read-write : The number of IOPS allowed for this disk. Only settable for UltraSSD disks.
--disk-mbps-read-write : The bandwidth allowed for this disk. Only settable for UltraSSD disks.
```

Both lines say *Only settable for UltraSSD disks*, and Microsoft's own guide to deploying Premium
SSD v2 sets both on that SKU. The compiler takes them:

```
ana@laptop:~/azure$ bicep build disk.bicep
ana@laptop:~/azure$ jq ".resources[0] | {sku, zones, properties}" disk.json
{
  "sku": {
    "name": "PremiumV2_LRS"
  },
  "zones": [
    "1"
  ],
  "properties": {
    "creationData": {
      "createOption": "Empty"
    },
    "diskSizeGB": 256,
    "diskIOPSReadWrite": 5000,
    "diskMBpsReadWrite": 145
  }
}
```

Three mistakes, each made on a copy of the file:

```
ana@laptop:~/azure$ bicep build disk-sku.bicep
ana@laptop:~/azure$ jq -r ".resources[0].sku.name" disk-sku.json
Premium_V2_LRS
ana@laptop:~/azure$ bicep build disk-text.bicep
/home/ana/azure/disk-text.bicep(19,24) : Warning BCP036: The property "diskMBpsReadWrite" expected a value of type "int | null" but the provided value is of type "'145'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
ana@laptop:~/azure$ bicep build disk-small.bicep
ana@laptop:~/azure$ jq -c ".resources[0].properties | {diskSizeGB, diskIOPSReadWrite, diskMBpsReadWrite}" disk-small.json
{"diskSizeGB":8,"diskIOPSReadWrite":5000,"diskMBpsReadWrite":145}
```

The misspelt SKU went into the template without a word: the SKU name is a plain string to the
compiler, and Azure would refuse it. The throughput written as text was refused. **The last one is
the mistake this section is about, and nothing here caught it**: 5,000 IOPS on an 8 GiB disk. Each
number is a valid integer; it is the arithmetic between them that is wrong, since 8 GiB allows
4,000. Azure checks it when the request arrives. You check it before.

## The machine caps the disk

A disk's rates are what the disk can do. What reaches the program is capped by the machine as
well, and lesson 1's table gave each size its own limit for all its disks together. Microsoft's
Ddsv5 page, read on 2026-10-30, gives the two sizes here, uncached:

| size | data disks | IOPS | MB/s | burst IOPS | burst MB/s |
| --- | --- | --- | --- | --- | --- |
| `Standard_D2ds_v5` | 4 | 3,750 | 85 | 10,000 | 1,200 |
| `Standard_D4ds_v5` | 8 | 6,400 | 145 | 20,000 | 1,200 |

The burst columns are the machine's own credits, the same 30-minute model as a disk's.

On `shop-db-1`, a `D4ds_v5`, the P30 and the P10 offer 5,000 + 500 = 5,500 IOPS, which fits under
6,400. Their throughput is 200 + 100 = 300 MB/s, and the machine takes 145. A backup reading the
data disk from end to end gets 145 MB/s once the machine's credits are spent, not the P30's 200.
The same disks on a `D2ds_v5` would be capped twice, at 3,750 IOPS and 85 MB/s. Microsoft's own
example is the same shape: a `D8s_v3` allowed 12,800 IOPS, with three P30 disks, asked for 15,000
and given 12,800.

That is where the numbers in `disk.bicep` come from. The P30 was 1 TiB only because 5,000 IOPS
came with nothing smaller; on Premium SSD v2 the same 5,000 IOPS sit on 256 GiB, 2,000 above the
free 3,000, and leave 1,400 of the machine's 6,400 for the log and the OS disk. The throughput is
145 MB/s, 20 above the free 125, because that is what the `D4ds_v5` takes. **A disk provisioned
past its machine buys a rate nothing can use**, and a larger rate on the disk is worth paying for
only together with a larger size; the size table of lesson 1 is the place to read both.

Nothing here measured a disk. These rates are Microsoft's targets, and the way to measure a real
disk is a benchmark such as `fio` on a machine in Azure, which this course cannot run.
