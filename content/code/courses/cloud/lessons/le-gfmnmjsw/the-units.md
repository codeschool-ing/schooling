---
title: The cloud bills per unit, not per server
version: 1
---

The picture most people arrive with is a hosting plan: you rent a server, and it costs so much a
month. **The cloud does not bill per server. It bills per unit of use**, and a server is only one of
the things being measured. The machine is counted in hours, its disk in gigabytes kept for a month,
the traffic leaving it in gigabytes, the requests reaching a storage bucket in thousands, and a
function in a unit called the GB-second. A month's bill is hundreds of lines, and each line is a
quantity multiplied by a price.

Every unit in the table below has already appeared in this course, attached to the service that
lesson was about. The prices are lines of the course's sheet, `python3 prices.py`, in the
`sa-east-1` column: the public list for São Paulo, in US dollars and excluding tax.

| unit | an example from the sheet | where it came from |
| --- | --- | --- |
| instance-hour | `t3.medium`, 0.06720 an hour | lesson 4 |
| GB-month provisioned | gp3 volume, 0.1520 per GB-month | lesson 5 |
| GB-month stored | S3 Standard, 0.04050 per GB-month | lesson 5 |
| request | S3 GET, 0.00056 per 1,000; Lambda, 0.20 per million | lessons 5 and 8 |
| hour of a network device | NAT gateway, 0.0930 an hour; load balancer, 0.0340 an hour | lesson 6 |
| GB processed | NAT gateway, 0.0930 per GB | lesson 6 |
| address-hour | public IPv4 address, 0.0050 an hour | lesson 6 |
| GB transferred | out to the internet, 0.1500 per GB; between zones, 0.0100 each way | lessons 6 and 9 |
| GB-second | Lambda, 0.0000166667 per GB-second | lesson 8 |

Two words in that table do more work than they seem to. A gp3 volume is billed by the size you
**provisioned**: a 100 GB volume holding 3 GB of files costs the same 15.20 dollars a month as a full
one. An S3 bucket is billed by what it **stores**: 3 GB in it cost 0.12 dollars. Lesson 5 drew the
difference between a block device and an object store; the bill draws it again.

## Billed for existing, billed for use

The units fall into two families, and telling them apart is most of reading a cloud bill.

**Some units are charged for existing.** An instance-hour, a gigabyte of provisioned disk, an hour of
a NAT gateway, an hour of a public address: each of these accrues whether anything happens or not. An
`m7i.large` that serves no request all night costs the same 0.16065 an hour as one that is busy. A
stopped instance stops its instance-hours, but the volume attached to it keeps its GB-months, because
the disk still exists.

**Other units are charged for use.** A request, a gigabyte sent out, a GB-second of a function: at zero
activity they cost zero, and they grow with traffic. A Lambda function nobody calls costs nothing,
which is the argument lesson 8 made for functions.

The families answer different questions. The first is what the design costs at rest, the floor you
pay on a quiet Sunday. The second is how the cost moves when the product is used, and that is the half
nobody can know exactly in advance.

## Why it is sold this way

Per-unit pricing is the reason the cloud can be rented for an hour and returned. Lesson 4's
autoscaling group adds two machines at noon and removes them at six, and the bill carries twelve
instance-hours for the afternoon rather than two more servers for a year. The same property is why a
bill cannot be read off a contract: **the cost is whatever was used**, and nobody signed off on the
usage.

Even a provider that quotes a machine at a monthly price, as some of lesson 3's smaller ones do,
meters something beside it: traffic past an allowance, a snapshot, an extra address. The units change
names between providers. The shape of a quantity times a price, summed over many lines, does not.
