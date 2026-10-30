---
title: Between zones, regions and continents
version: 1
---

**Inside Google Cloud, where the bytes go decides whether they cost anything at all.** A bucket read
by a machine, a cluster or a query in the same location sends its bytes for nothing, and only the
operations are billed. A bucket read from another region pays per GiB, and from São Paulo the price
barely changes with the distance. And one piece of networking that many projects have, Cloud NAT,
charges for every byte it carries even when the destination is the bucket next door.

## Same location: free

The storage pricing page lists the cases that cost nothing, and the first is the one that matters:
**data that moves within the same location**. A bucket in `southamerica-east1` read by a virtual
machine in `southamerica-east1-b`, by a Dataproc cluster of lesson 23 in the same region, or by a
BigQuery dataset whose location is `southamerica-east1`, sends no billable bytes. **Zones do not
count**: the page says in so many words that moving data between zones of one region is the same
location.

Two traps sit inside "same location". **A region is not the same location as a multi-region**, even
when the region is inside it, so a bucket in the `US` multi-region read from `us-east1` pays. And
BigQuery's `US` and `EU` locations are counted as `us-central1` and `europe-west4`. That matters to a
Brazilian company on the day somebody creates a dataset in `US` because a tutorial did, and it is why
a dataset's location is worth naming every time one is created.

## Another region: a price set by where the bucket is

For everything else inside Google Cloud, the page prints a matrix: the bucket's location down the
side, the destination across the top, a price per GiB in each cell. Its rows for three origins:

| bucket in → read from | Northern America | Europe | Latin America | Asia |
|---|---|---|---|---|
| Northern America | 0.02 | 0.05 | 0.14 | 0.08 |
| Europe | 0.05 | 0.02 | 0.14 | 0.08 |
| **Latin America** | **0.14** | **0.14** | **0.14** | **0.14** |

**Every cell of the Latin America row is 0.14.** A bucket in São Paulo pays the same to send a GiB to
Santiago as to send it to Iowa or Frankfurt, and that is the most expensive row of the matrix. A
company in North America pays 0.02 to move data between two of its regions; a company in Brazil pays
seven times that, because the price is about Google's network from South America and not about the
kilometres.

Quitanda's legal team was once asked for a copy of the 5 TiB lake in `us-east1`, for a partner who
works there. The arithmetic for that, and for the next two cases:

```
ana@laptop:~/gcp$ python3 -c 'print(round(5 * 1024 * 0.14, 2), round(2 * 1024 * 0.045, 2), round(500 * 0.01, 2))'
716.8 92.16 5.0
```

**The copy is 716.80, once**, and every change replicated after it pays the same rate. It is also why
this course keeps Quitanda's data in `southamerica-east1`: a Brazilian company's data often has to stay, and moving it is a
line on the bill as well as a legal question. The same is true of a dual-region or a multi-region
bucket, where Google copies every write to a second region and the page bills it as inter-region
replication, per GiB written.

## Machines, zones, and the NAT that charges for the bucket

**A bucket does not care about zones; two machines do.** Traffic between virtual machines in two
zones of one region costs 0.01 a GiB on the network pricing page, billed to the project of the one
that sends, and the same page prices traffic to Cloud SQL in the same region like traffic between
machines. A database's primary in one zone and its standby in another are lesson 7's subject; an
application in zone `a` that reads 500 GiB a month from a database in zone `b` is the third number
above, 5.00.

**Cloud NAT is where a bucket in the same region starts to cost money.** A machine with no external
address reaches the internet through a Cloud NAT gateway, which `gcp-foundations` lesson 17 builds.
Without anything else configured, it reaches Cloud Storage through it too, because
`storage.googleapis.com` is a public address. The network pricing page charges Cloud NAT 0.045 per
GiB processed, in either direction, in every region, on top of an hourly price per machine using it.
A nightly job on a private machine that reads 2 TiB a month from the lake pays 92.16 a month in NAT
processing alone, for bytes that never left São Paulo.

**Private Google Access removes that line.** It is a setting on the subnet, at no charge of its own,
that lets machines with no external address reach Google's APIs over Google's network directly, so
the traffic to the bucket stops going through the NAT gateway. The same lesson 17 turns it on. It is
the cheapest change in this lesson and among the most often missed, because nothing breaks without
it; the bill is merely larger.

None of this networking exists on the laptop. fake-gcs-server answers on `localhost`, there are no
zones to cross and no gateway to pay, and the numbers in this section are the pricing pages
multiplied by counts.
