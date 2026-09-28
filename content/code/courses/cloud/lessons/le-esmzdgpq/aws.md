---
title: "AWS: the oldest, and the vocabulary"
version: 1
---

Amazon Web Services opened S3, its object storage, and EC2, its virtual machines, to the public in
2006. Nobody else sold computing that way at the time: a machine by the hour, through an API, with
no contract and no salesperson. **Being first made AWS's names the words of the whole field.**

The clearest instance is object storage. DigitalOcean's Spaces, Hetzner's Object Storage, Akamai's
Object Storage and Cloudflare's R2 all describe themselves as **S3-compatible**: they answer the API
that S3 defined, so a program written against S3 talks to them by changing an address and a key.
Nobody describes a product as compatible with the one that came second.

## The account and the region

The unit you create first at AWS is an **account**. Everything you build belongs to one account,
and the bill arrives per account. A company rarely keeps one: it keeps many, one per team or per
environment, grouped under AWS Organizations so they share one bill and one set of rules. The
`aws-foundations` course sets that up; here it is enough to know that the account is the box.

Inside the account, almost everything lives in a **region** you choose, and a region has a code:

| code | where |
| --- | --- |
| `sa-east-1` | São Paulo |
| `us-east-1` | Northern Virginia |

A machine created in `sa-east-1` exists only there. The console shows one region at a time, which
is why a person who "cannot find the server" is usually looking at the wrong region rather than at
an empty account. Lesson 9 is about what a region is made of and what the distance between two of
them costs in milliseconds.

`us-east-1` is the oldest region, and it is special in a way that surprises people. Some things
that serve the whole world are managed there: a TLS certificate for AWS's content delivery network,
CloudFront, has to be requested in `us-east-1` whichever region the rest of your system lives in.
Even the price list you will read later in this lesson is served from an address with
`us-east-1` in it.

## What it is known for

**It is known first for breadth.** On the day this lesson was captured, AWS's price index listed 272 separate offers, one
per priced service. Some are the core of the previous section, and many are things only a
hyperscaler sells: a managed key-value database (DynamoDB), a queue (SQS), a data warehouse
(Redshift), functions (Lambda, the subject of lesson 8).

Then for **depth inside each service**. EC2 alone offers machines by the hundred, in families named by what
they are for: general purpose, compute optimised, memory optimised, with Intel, AMD and Amazon's
own Arm processors, Graviton. The price sheet in this course carries a few of them, and in a name
like `m7g` the `g` says Graviton.

And for its ecosystem. Because AWS was first, third-party tools, tutorials and job adverts assume it
more than any other provider. That is not a technical property, and it is still a reason teams give
for choosing it.

## What the breadth costs

The same breadth is the main complaint. There are several ways to do most things — a container can
run on EC2, on ECS, on EKS, on Fargate, on Lambda — and choosing between them is a
skill of its own. The console is large. And **the bill has a line for everything**: a virtual
machine arrives as the machine's hours, its disk, its public address and the data it sent, each
metered apart. You will see those lines priced in the sheet at the end of this lesson, and lesson
10 is about reading them as a bill.
