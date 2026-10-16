---
title: What a storage class trades
version: 1
---

**A storage class is a price for keeping a gigabyte paired with a price for reading it back**, and
every class below Standard buys a lower first price with a higher second one. People tend to read the
list as "fast, slower, slowest", as if the cheap classes were slower disks. They are not slower in the
same way. Standard-IA and Glacier Instant Retrieval answer a read in milliseconds, exactly like
Standard; what they change is the bill for that read and the bill for leaving early. Only the two
archive classes are slow, and there the object is not readable at all until you ask for it back.

Every class is chosen per object, not per bucket. One bucket can hold today's orders in Standard,
last year's in Glacier Instant Retrieval and the 2019 audit exports in Deep Archive, side by side
under the same prefixes.

## The prices

The price sheet from lesson 1 prints the S3 block. This lesson, like every lesson of the course,
assumes moto running in its own terminal and the four lines of lesson 1's "Your lab, in brief" typed
in this one; the sheet itself needs neither, only the cache it filled the first time:

```
ana@laptop:~/aws$ python3 prices.py s3
AWS public price list, sa-east-1, USD, excluding tax

S3 storage, USD per GB-month
  Standard, first 50 TB                                 0.04050  GB-month
  Intelligent-Tiering, frequent                         0.04050  GB-month
  Standard-IA                                           0.02210  GB-month
  One Zone-IA                                           0.01770  GB-month
  Glacier Instant Retrieval                             0.00830  GB-month
  Glacier Flexible Retrieval                            0.00765  GB-month
  Glacier Deep Archive                                  0.00320  GB-month

S3 requests, USD per 1,000
  Standard: PUT, COPY, POST, LIST                       0.00700  per 1,000
  Standard: GET and the rest                            0.00056  per 1,000
  Standard-IA: GET                                      0.00100  per 1,000
  Glacier Instant Retrieval: GET                        0.01000  per 1,000
  Intelligent-Tiering monitoring, per 1,000 objects     0.00250  per month

S3 retrieval, USD per GB
  Standard-IA                                           0.01000  GB
  Glacier Instant Retrieval                             0.03000  GB
  Glacier Flexible, expedited                           0.04200  GB
  Glacier Flexible, standard                            0.01400  GB
  Deep Archive, standard                                0.02800  GB
  Deep Archive, bulk                                    0.00800  GB
```

**Standard is 0.04050 a GB-month and Deep Archive is 0.00320**, so the archive keeps a gigabyte for
less than a twelfth of the price. The retrieval block is the other half. Reading a gigabyte back costs
nothing extra from Standard, 0.01000 from Standard-IA, 0.03000 from Glacier Instant Retrieval, and
0.02800 from Deep Archive at the standard speed.

## What else each class trades

The price sheet shows two of the trades. AWS's documentation for S3 storage classes states the rest,
and none of it is something moto can show, because moto keeps every object in the same dictionary
whatever its class says:

| class | zones | minimum days billed | smallest object billed | first byte |
|---|---|---|---|---|
| Standard | at least 3 | none | none | milliseconds |
| Intelligent-Tiering | at least 3 | none | not monitored under 128 KB | milliseconds, in its default tiers |
| Standard-IA | at least 3 | 30 | 128 KB | milliseconds |
| One Zone-IA | 1 | 30 | 128 KB | milliseconds |
| Glacier Instant Retrieval | at least 3 | 90 | 128 KB | milliseconds |
| Glacier Flexible Retrieval | at least 3 | 90 | 40 KB added per object | minutes to hours, after a restore |
| Glacier Deep Archive | at least 3 | 180 | 40 KB added per object | hours, after a restore |

**The minimum duration is a bill for leaving early.** An object deleted, overwritten or moved to
another class before its minimum is charged for the days that remain, so a file kept in Deep Archive
for ten days is billed for 180. One terabyte, 1,024 GB in the gigabytes the price list counts, for
ten days at 0.00320 would be about 1,024 × 0.00320 × 10 / 30 = 1.09 USD; billed for 180 days it is
1,024 × 0.00320 × 6 = 19.66.

**The smallest billed size punishes small files.** A 10 KB object in Standard-IA is billed as
128 KB, almost thirteen times its size. And an object in either Glacier archive class carries
40 KB more than its own bytes: 32 KB of index charged at the archive's price and 8 KB of name and
metadata charged at Standard's. A million 10 KB log lines archived one per object are paid for as five
times their size, part of it at Standard's price.

**One Zone-IA keeps one copy of the data in one zone.** Every other class spreads an object across
at least three zones of the region. One Zone-IA is the price of losing that: if the zone is
destroyed, so is the data. It fits something that can be produced again, such as a thumbnail made
from an original kept elsewhere, and never the only copy of anything.

The figure puts the two trades the price sheet prints on one page: what a gigabyte costs to keep,
against how long the first byte takes and what reading a gigabyte costs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 326\" role=\"img\" aria-label=\"Five S3 classes on two axes. Across, the price of keeping a GB for a month; down, how long the first byte takes. In milliseconds: Standard at 0.0405 with nothing extra to read; Standard-IA at 0.0221, 0.010 per GB read; Glacier Instant Retrieval at 0.0083, 0.030 per GB read. In minutes to hours: Glacier Flexible Retrieval at 0.00765, 0.014 per GB. In hours to two days: Deep Archive at 0.0032, 0.008 to 0.028 per GB. The cheaper the shelf, the dearer or slower the door.\" data-fig=\"l02-classes\"><path d=\"M150.0 112.0 L700.0 112.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">milliseconds</text><path d=\"M150.0 197.0 L700.0 197.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">minutes to hours</text><path d=\"M150.0 282.0 L700.0 282.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"240.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hours to two days</text><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">first byte</text><path d=\"M150.0 282.0 L700.0 282.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M160.0 282.0 L160.0 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"160.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M277.8 282.0 L277.8 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"277.8\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.01</text><path d=\"M395.6 282.0 L395.6 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"395.6\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.02</text><path d=\"M513.3 282.0 L513.3 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"513.3\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.03</text><path d=\"M631.1 282.0 L631.1 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"631.1\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.04</text><text x=\"700.0\" y=\"316.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">keeping, USD per GB-month</text><circle cx=\"637.0\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"637.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard</text><text x=\"637.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">read: nothing extra</text><circle cx=\"420.3\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"420.3\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard-IA</text><text x=\"420.3\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">read: 0.010 a GB</text><circle cx=\"257.8\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"251.8\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Glacier Instant Retrieval</text><text x=\"251.8\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">read: 0.030 a GB</text><circle cx=\"250.1\" cy=\"155.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"244.1\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Glacier Flexible Retrieval</text><text x=\"244.1\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">read: 0.014 a GB</text><circle cx=\"197.7\" cy=\"240.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"191.7\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Deep Archive</text><text x=\"191.7\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">read: 0.008 to 0.028 a GB</text></svg>", "caption": "What a GB costs to stay, against the time and the price to come back. One Zone-IA is left out: the sheet does not print its read price."}
```

Two classes are missing from the table on purpose. **Reduced Redundancy** is an old class that AWS
no longer recommends, and the price sheet does not print it. S3 Express One Zone belongs to a
different kind of bucket, a directory bucket in a single zone built for very low latency, which this
course does not use.
