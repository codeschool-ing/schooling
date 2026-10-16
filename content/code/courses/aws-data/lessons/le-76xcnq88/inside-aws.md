---
title: Between zones, regions and subnets
version: 1
---

**Inside AWS, where the bytes go decides whether they cost anything at all.** Reading S3 from a
machine in the same region is free of transfer charges, and only the requests are billed. Crossing a
zone boundary between two of your own machines costs a little in each direction. Leaving the region
costs almost as much as going to the internet. And one piece of networking that many accounts have,
the NAT gateway, charges for every byte it carries even when the destination is S3 next door.

The lines, from the sheet:

```
  between zones, each direction                         0.01000  GB
  to us-east-1                                          0.13800  GB
```

## Zones and regions

**S3 is a regional service, so reading it from any zone of São Paulo costs no transfer.** The zone
charge is for traffic between your own resources in different zones: a database in one zone
replicating to its standby in another, which lesson 7 meets with Multi-AZ, or a cluster whose nodes
sit in two zones. Each GB is charged as it leaves one zone and again as it enters the other, so
500 GB a month of replication is 500 × 0.01000 × 2 = 10.00.

**Copying to another region is charged like a small internet.** Quitanda's legal team asked once for
a copy of the 5 TB lake in us-east-1, for a partner who works there. That is 5,120 GB × 0.13800 =
706.56 for the copy, once, and every change replicated after it pays the same rate. It is also why
lesson 1 keeps the data in São Paulo: a Brazilian company's data usually has to stay, and moving it
is a line on the bill as well as a legal question.

## The NAT gateway, and the endpoint that replaces it

Machines in a private subnet reach the internet through a NAT gateway, which `aws-foundations`
lesson 17 builds. Without anything else configured, they also reach S3 through it, because S3's
address is a public one. **A NAT gateway charges for every GB it processes**, in either direction,
and this course's price sheet does not read the offer that price lives in. The `cloud` course's
sheet does: `cloud` lesson 10, in "Reading the public price list", prints a NAT gateway in São Paulo
at 0.0930 per GB processed, on top of 0.0930 an hour for existing.

At that price, a nightly job in a private subnet that reads 2 TB a month from the lake pays
2,048 × 0.0930 = 190.46 a month in NAT processing alone, for traffic that never left São Paulo.

**A gateway endpoint for S3 costs nothing and removes that charge**, as `aws-foundations` lesson 19
explains: an entry in the subnet's route table that sends S3's addresses to S3 privately, past the NAT
gateway. The 190.46 becomes 0.00, and the bucket policy of lesson 4 can then insist on
`aws:SourceVpce` so that the bucket is read only that way. It is the cheapest change in this lesson
and among the most often missed, because nothing breaks without it; the bill is merely larger.

None of this networking exists in moto, which has no zones to cross and no gateway to pay. The
numbers are the price lists multiplied by counts.
