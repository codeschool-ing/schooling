---
title: A region is a place
version: 1
---

The picture most people arrive with is a region as a setting: a drop-down at the top of the console,
like the time zone on a laptop, that changes a label and nothing else. **A region is a place.** It is
a geographic area, such as São Paulo, Northern Virginia or Frankfurt, where a provider runs several
datacentres grouped into isolated zones, which are the next section. When you create a virtual
machine, a bucket or a database, it is created in one region and it physically sits there.

Each provider names them its own way. AWS calls São Paulo `sa-east-1`, Azure calls it `brazilsouth`
and Google Cloud calls it `southamerica-east1`. The names differ and the idea does not, so this
lesson uses AWS's names because the course's price sheet does.

A region is chosen per resource, not per account. One account can hold an instance in São Paulo, a
bucket in Virginia and a database in Frankfurt, and nothing stops you from building exactly that by
accident. Three consequences follow from the choice, and each one bites somebody.

## Data stays where you put it

**A resource lives in its region until you move it.** A bucket created in `sa-east-1` keeps its
objects in São Paulo. The provider does not copy them to another region on its own initiative:
copying across regions is something you configure, and pay for, as this lesson's section on
multiple regions shows. So the region is where the data-residency promise from lesson 2 is kept,
and a replica you set up in another country is where it is broken.

## Services differ by region

**A region is not a copy of every other region.** New services and new instance types arrive in some
regions before others, and a service can be missing from a region for years. A design that depends
on one managed service has to check that the service exists in the region it will run in, before
anything is built. That check is a table on the provider's own site, and the vendor courses,
`aws-foundations`, `azure-foundations` and `gcp-foundations`, show where each one keeps it.

## Prices differ by region

**The same instance has a different price in every region.** Same size, same operating system, same
hour. The course's price sheet is the AWS public list for `sa-east-1` and `us-east-1`, in US dollars,
excluding tax, at the offer versions it prints:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | sed -n '1,17p'
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

EC2, Linux, on demand, USD per hour
  t3.micro    2 vCPU   1 GiB              0.01680      0.01040
  t4g.small   2 vCPU   2 GiB              0.02680      0.01680
  t3.medium   2 vCPU   4 GiB              0.06720      0.04160
  m7i.large   2 vCPU   8 GiB              0.16065      0.10080
  m7g.large   2 vCPU   8 GiB              0.13010      0.08160
  c7i.large   2 vCPU   4 GiB              0.13755      0.08925
  m7i.xlarge  4 vCPU  16 GiB              0.32130      0.20160
```

Read two lines of it. A `t3.micro` costs 0.01680 an hour in São Paulo and 0.01040 in Virginia, and
0.01680 / 0.01040 = 1.615: the same machine costs about 62% more in `sa-east-1`. An `m7i.large`
costs 0.16065 against 0.10080, and 0.16065 / 0.10080 = 1.594, about 59% more. **The ratio is not one
fixed number**, but every on-demand line in that block sits between 1.54 (the `c7i.large`) and 1.62.

Over a 30-day month of 720 hours, one `m7i.large` is 0.16065 × 720 = 115.67 dollars in São Paulo and
0.10080 × 720 = 72.58 in Virginia. The difference, 43.09 dollars a month for one machine, is the price
of the region and nothing else.

The sheet says what the prices are and not why they differ. Whatever the reasons, they belong to the
provider, and what you can act on is the number. It is one of the five questions in this lesson's
checklist for choosing a region, and it is rarely the first one: a cheaper region that breaks the
law you operate under, or puts your users a hundred milliseconds away, is not cheaper.
