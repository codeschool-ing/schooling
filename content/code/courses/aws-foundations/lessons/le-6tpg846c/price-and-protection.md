---
title: What CloudFront costs, and what it keeps out
version: 1
---

**CloudFront bills by where the viewer is**, not by where the shop is: a gigabyte sent to a customer
in Recife is priced as South America, a gigabyte to one in Lisbon as Europe, whatever region the
origin lives in. Three lines make most of the bill, the bytes out to viewers, the requests, and the
invalidation paths past an allowance, and one line that matters is the one that costs nothing. The
common wrong picture is that a CDN is an extra layer of cost on top of the region's. For bytes that
leave AWS it is usually the cheaper door.

## The lines in the price list

CloudFront's offer, like Route 53's, files its prices under `aws-other`, with the viewer's part of
the world at the front of each usage type:

```
ana@laptop:~/aws$ python3 price.py AmazonCloudFront 20260916132208 aws-other SA-DataTransfer-Out-Bytes US-DataTransfer-Out-Bytes Invalidations
AmazonCloudFront 20260916132208, published 2026-09-16, USD
SA-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.1100
     10,240 to    51,200 GB   0.1050
     51,200 to   153,600 GB   0.0900
    153,600 to   512,000 GB   0.0800
    512,000 to 1,048,576 GB   0.0600
  1,048,576 to 5,242,880 GB   0.0500
  5,242,880 to       Inf GB   0.0400
US-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.0850
     10,240 to    51,200 GB   0.0800
     51,200 to   153,600 GB   0.0600
    153,600 to   512,000 GB   0.0400
    512,000 to 1,048,576 GB   0.0300
  1,048,576 to 5,242,880 GB   0.0250
  5,242,880 to       Inf GB   0.0200
Invalidations
          0 to     1,000 URL  0.0000
      1,000 to       Inf URL  0.0050
```

Requests are priced per request, too small for four decimals, so lesson 21's `per-million.py` reads
them from the file `price.py` just downloaded:

```
ana@laptop:~/aws$ python3 per-million.py AmazonCloudFront 20260916132208 aws-other SA-Requests-Tier2-HTTPS US-Requests-Tier2-HTTPS
SA-Requests-Tier2-HTTPS
  from             0  2.20 per million
US-Requests-Tier2-HTTPS
  from             0  1.00 per million
```

And the line that costs nothing is in the data transfer offer lesson 1 read, beside the 0.15 it
quoted for São Paulo to the internet:

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-CloudFront-Out-Bytes SAE1-DataTransfer-Out-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
SAE1-CloudFront-Out-Bytes
          0 to       Inf GB   0.0000
SAE1-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.1500
     10,240 to    51,200 GB   0.1380
     51,200 to   153,600 GB   0.1260
    153,600 to       Inf GB   0.1140
```

Both offers carry the version `20260916132208`, published on **16 September 2026**, in dollars:

| | to a viewer in South America | to a viewer in the US |
|---|---|---|
| a GB out of CloudFront, first 10 TB of the month | 0.110 | 0.085 |
| a million HTTPS requests | 2.20 | 1.00 |
| a GB from `sa-east-1` to CloudFront | free | free |
| a GB from `sa-east-1` straight to the internet, first 10 TB | 0.150 | 0.150 |
| an invalidation path, first 1,000 of the month | free | free |
| an invalidation path after that | 0.005 | 0.005 |

## The shop's month, both ways

Say the shop sends 5 TB a month to customers in Brazil, in 50 million HTTPS requests.

- **Straight from the region**: 5,120 GB × 0.150 = **768.00 dollars** of transfer.
- **Through CloudFront**: 5,120 GB × 0.110 = **563.20 dollars** of transfer, plus
  50 × 2.20 = **110.00** of requests, so 673.20, and the transfer from the bucket and the load
  balancer to CloudFront is free.

**The CDN is cheaper by 94.80 dollars a month before it has saved anything else**, and it has: every
request answered at the edge is one the load balancer did not count in its capacity units, and one
the bucket did not count as a `GET`. The numbers move the other way only for traffic that cannot be
cached at all and is mostly small requests, where the request line outweighs the transfer it saves.

**The price class is the setting that can quietly undo this.** `PriceClass_All`, which the shop's
distribution uses, serves every viewer from the nearest edge. The two cheaper classes,
`PriceClass_100` and `PriceClass_200`, leave out the dearest parts of the world, and according to
AWS's documentation South America is left out of both: a Brazilian customer would then be served
from an edge in North America, at a lower price per gigabyte and a latency the customer feels. For a shop whose customers are
in Brazil the class is not a saving, it is the wrong edge.

Invalidations, last: the shop's 1,500 paths in a busy month cost 500 × 0.005 = **2.50 dollars**, and
the same month with versioned file names costs nothing.

## What a distribution keeps out

A distribution is also the front door, and four things can be set on it. **None of them was put to
the test here**: moto stores some of them and enforces none, so the behaviour below is AWS's
documented one.

- **A behaviour can demand a signature on every request**, in a signed URL or a signed cookie made
  with a key the shop holds; CloudFront checks it against the public half, kept in a **key
  group** on the distribution. A download sold to one customer gets a URL that works until a time
  the shop chose, and nobody else's link works at all.
- **A distribution can refuse whole countries**, or allow only some, by the viewer's address.
  moto keeps the setting, and this distribution's says nobody is refused:

```
ana@laptop:~/aws$ aws cloudfront get-distribution-config --id $id --query "DistributionConfig.Restrictions"
{
    "GeoRestriction": {
        "RestrictionType": "none",
        "Quantity": 0
    }
}
```

- **AWS WAF filters requests at the edge**, through a web ACL attached to the distribution,
  before they cost the origin anything: rate limits per address, rules against common attacks, blocks by country or
  header. For CloudFront the web ACL is made with the scope `CLOUDFRONT`, in `us-east-1`, the rule from
  the first section of this lesson once more.
- **AWS Shield Standard is on for every distribution**, at no charge, against the commonest floods
  of traffic; the paid **Shield Advanced** adds a response team and cost protection.

**The origin has to be closed as well.** A distribution in front of a load balancer that anybody may
still reach directly is a front door beside an open window. OAC closes the bucket, as the first
section did. For the load balancer, AWS publishes a managed prefix list of CloudFront's addresses,
and a security group rule that admits only that list, lesson 18's subject, leaves CloudFront the
only way in.
