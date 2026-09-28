---
title: Reading the public price list
version: 1
---

Every price in this lesson, and in this course, is a line of one document: **the public price list
AWS publishes as JSON**, readable by anybody without an account. The course reads it with
`prices.py`, the program beside `course.json`, and this is the whole sheet it prints:

```
ana@laptop:~/cloud$ python3 prices.py
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

EC2, Linux, 1-year reserved, no upfront, USD per hour
  t3.micro                                0.00960      0.00650
  t4g.small                               0.01540      0.01050
  t3.medium                               0.03860      0.02610
  m7i.large                               0.09956      0.06668
  m7g.large                               0.08060      0.05400
  c7i.large                               0.09085      0.05904
  m7i.xlarge                              0.19911      0.13336

EBS, USD per GB-month
  gp3 SSD volume                           0.1520       0.0800
  st1 HDD volume                           0.0860       0.0450
  snapshot                                 0.0680       0.0500

Networking, USD
  NAT gateway, per hour                    0.0930       0.0450
  NAT gateway, per GB processed            0.0930       0.0450
  load balancer (ALB), per hour            0.0340       0.0225
  public IPv4 address, per hour            0.0050       0.0050

S3, USD per GB-month (first tier)
  Standard                                0.04050      0.02300
  Standard-Infrequent Access              0.02210      0.01250
  Glacier Instant Retrieval               0.00830      0.00400
  Glacier Flexible Retrieval              0.00765      0.00360

S3 requests, USD per 1,000
  PUT, COPY, POST, LIST                   0.00700      0.00500
  GET and the rest                        0.00056      0.00040

EFS, USD per GB-month
  Standard                                 0.5700       0.3000

Data transfer, USD per GB
  out to the internet, first 10 TB         0.1500       0.0900
  out to the internet, next 40 TB          0.1380       0.0850
  out to the internet, next 100 TB         0.1260       0.0700
  out to the internet, over 150 TB         0.1140       0.0500
  between zones, each direction            0.0100       0.0100
  to the other region                      0.1380       0.0200
  in from the internet                     0.0000       0.0000

Lambda, USD
  per 1 million requests                     0.20         0.20
  per GB-second, x86                 0.0000166667 0.0000166667
  per GB-second, Arm                 0.0000133334 0.0000133334
  free tier, requests                   1,000,000    1,000,000
  free tier, GB-seconds                   400,000      400,000
```

## Offers and versions

The list is split into **offers**, one per service: `AmazonEC2` holds the machines and their disks,
`AmazonVPC` the public addresses, `AWSDataTransfer` the traffic, and so on. Each offer is published as
one JSON file per region, and **each offer keeps every version it ever published**. A version is named
after the moment it was published, so `20260919002359` is Lambda's price list as it stood at
00:23:59 UTC on 19 September 2026.

`prices.py` names one version of each offer and never asks for "the latest". That is why the sheet
above will print the same numbers next year, when AWS will have published many newer versions and
some prices will have moved. **A number in a lesson has to be reproducible, and only a pinned
version is.** The cost is that the sheet is a photograph. For a real decision you read the current
version, or use the provider's own calculator, which reads the current list for you: the AWS Pricing
Calculator, the Google Cloud Pricing Calculator, the Azure pricing calculator.

The header also says what the numbers are not. They are USD and exclude tax. They are the public
price, before any discount a company negotiates, any credit, and any commitment, which the section on
commitments comes to.

## What a line is

The sheet is arithmetic on the JSON, and there is no magic in it. Here is Lambda's request price in
São Paulo, read out of the raw file with `curl` and `jq`, in two steps:

```
ana@laptop:~/cloud$ url=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSLambda/20260919002359/sa-east-1/index.json
ana@laptop:~/cloud$ curl -s "$url" | jq '.products[] | select(.attributes.usagetype == "SAE1-Request") | .sku'
"7TZ969MZND3Z6HD7"
ana@laptop:~/cloud$ curl -s "$url" | jq '.terms.OnDemand["7TZ969MZND3Z6HD7"][].priceDimensions[] | {description, unit, pricePerUnit}'
{
  "description": "AWS Lambda - Total Requests - South America (Sao Paulo)",
  "unit": "Request",
  "pricePerUnit": {
    "USD": "0.0000002000"
  }
}
```

The first step finds the **product**. Every product has a SKU, an opaque code, and a set of
attributes; the one that says what is being measured is `usagetype`. `SAE1-Request` reads as two
parts: `SAE1` is the region prefix for São Paulo, and `Request` is the thing counted. A product is not
a price yet. It is the definition of a meter.

The second step reads the product's **term**. `OnDemand` is the term with no commitment; the EC2 file
also carries `Reserved` terms, which is where the sheet's second block of machine prices comes from.
Inside the term, each **price dimension** carries the unit and the price for one unit: 0.0000002 USD
per request. Multiply by a million and you have the sheet's line, `per 1 million requests 0.20`.

**A line of the sheet is therefore three things joined together**: a product that says what is
measured and where, a term that says on what conditions, and a price dimension that says how much per
unit. The description string is there for people, and the program never reads it.

## Tiers

A price dimension also has a `beginRange` and an `endRange`, left out of the query above because for
Lambda requests they are `0` and `Inf`: one price for every request. Where they are not, the product
is **tiered**. Traffic out to the internet is the clearest case on the sheet: 0.1500 per GB for the
first 10 TB of the month, then 0.1380, 0.1260 and 0.1140 as the volume grows. Each tier is its own
price dimension of the same product, with its own range. A tier applies to the gigabytes inside its
range, not to the whole month, so the 11th terabyte costs less than the first ten and the first ten
still cost 0.1500 each.

Free allowances are tiers as well, as the section on free tiers shows with the same query: a price of
zero, up to a limit.
