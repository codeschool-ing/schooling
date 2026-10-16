---
title: The way out, priced
version: 1
---

The function is in private subnets, it can reach its database, and it can reach nothing else.
**The first call it makes to S3, to Secrets Manager or to a payment API waits until its timeout
and fails**, with no error that mentions the network, because the packets went nowhere. There are
two ways out, and they cost very differently.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A function in a private subnet of a VPC reaches the database beside it directly. To go further it has three ways out: a NAT gateway, priced per hour and per gigabyte, to the whole internet; a gateway endpoint, at no charge, to S3 and DynamoDB; and an interface endpoint, a network interface in the subnet, to one AWS service each, such as Secrets Manager or SQS.\"><defs><marker id=\"wy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"440\" height=\"248\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"28\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">VPC</text><rect x=\"32\" y=\"52\" width=\"180\" height=\"196\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"44\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">private subnet</text><rect x=\"48\" y=\"90\" width=\"148\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"122\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">function</text><rect x=\"48\" y=\"180\" width=\"148\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"122\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">database</text><path d=\"M122 132 L122 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><rect x=\"260\" y=\"52\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">NAT gateway</text><text x=\"350\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">0.093/h + 0.093/GB</text><rect x=\"260\" y=\"122\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">gateway endpoint</text><text x=\"350\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">no charge, routes only</text><rect x=\"260\" y=\"192\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">interface endpoint</text><text x=\"350\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">an ENI per subnet, one service</text><path d=\"M198 104 L256 80\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><path d=\"M198 112 L256 146\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><path d=\"M198 120 L256 214\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><rect x=\"500\" y=\"40\" width=\"204\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">the internet</text><text x=\"602\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">and every public endpoint</text><rect x=\"500\" y=\"122\" width=\"204\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">S3, DynamoDB</text><rect x=\"500\" y=\"192\" width=\"204\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Secrets Manager, SQS, ...</text><path d=\"M442 77 L496 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><path d=\"M442 147 L496 147\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><path d=\"M442 217 L496 217\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path></svg>", "caption": "A private subnet has no route to the internet, and that includes the public endpoints of AWS's own services. A NAT gateway opens all of it, by the hour and by the gigabyte; endpoints open one service each, and the gateway kind costs nothing."}
```

## A NAT gateway: everything, by the hour and by the gigabyte

A NAT gateway sits in a public subnet with a public address, and a route in the private subnets'
table sends their internet traffic to it. `aws-foundations` lesson 17 builds one. It opens the
whole internet to the function, and the price sheet of 16 October 2026 has its two meters:

```
@@CAP:nat-price@@
```

**Both meters run on their own.** The hourly charge is paid for every hour the gateway exists,
used or not: 0.093 × 730 = 67.89 USD a month in sa-east-1. A NAT gateway lives in one zone, and a
function in two zones whose single gateway is in zone a loses the internet when zone a does, so
the arrangement AWS recommends is one gateway per zone: two of them for this lesson's two subnets,
135.78 USD a month before a single byte. The data charge is 0.093 USD for every gigabyte the
gateway processes, in either direction. A function that downloads 200 GB a month from S3 through
it adds 200 × 0.093 = 18.60 USD, for traffic that never needed to leave AWS at all.

That last figure is the one worth looking at twice. **Traffic to S3 through a NAT gateway pays the gateway's data charge for
something that has a free route**, and the next
paragraphs are that route.

## Endpoints: one service at a time

A VPC endpoint gives the subnets a private path to one AWS service, without the internet and
without a NAT gateway. `aws-foundations` lesson 19 introduces both kinds; what matters here is
which one the function needs.

A **gateway endpoint** exists for S3 and DynamoDB only. It is an entry in the route table that
sends traffic for the service's address ranges to the endpoint, and it costs nothing, neither by
the hour nor by the gigabyte. For a function that reads and writes S3, it removes the largest
part of a NAT gateway's data bill outright.

An **interface endpoint** exists for most other services: Secrets Manager, SQS, SNS, Step
Functions, CloudWatch Logs, ECR. It is a network interface in each subnet you choose, with a
private address that the service's usual name resolves to inside the VPC, so the SDK needs no
change. It is billed per hour per zone and per gigabyte; **those prices are not on this course's
price sheet**, so this lesson quotes no figure for them, and AWS's pricing page for PrivateLink is
where they are published.

Both run against moto. The route table is the one the VPC was created with:

```
@@CAP:endpoints@@
```

The gateway endpoint appears in the route table as a route to a prefix list, `pl-` and an id,
which is the set of S3 addresses in the Region, pointing at the endpoint. The interface endpoint
made two network interfaces, one in each subnet, and they are the two lines of the last listing.
**Those are the only interfaces in the account**: the function, whose Hyperplane interfaces AWS
would have placed in the same subnets, has none in moto, as the previous section showed.

## Choosing between them

The arithmetic decides most cases, and the shape of it is short:

- a function that only talks to its database needs **neither**: no route out at all is the
  cheapest and the most private arrangement there is;
- a function that also uses S3 or DynamoDB needs **a gateway endpoint**, which is free;
- a function that also uses two or three other AWS services needs **interface endpoints** for
  them, priced per service and per zone;
- a function that calls something on the public internet, a payment provider or a webhook, needs
  **a NAT gateway**, and then the gateway endpoint as well, so that S3 traffic does not pay the
  gateway's data charge on its way past.

A NAT gateway is shared by everything in the VPC, so the 135.78 USD a month is often already
being paid for other reasons, and a function joining that VPC adds only its data. The mistake is
creating the gateway for one function, and then paying its data charge on traffic to S3 that an
endpoint would have carried for nothing.
