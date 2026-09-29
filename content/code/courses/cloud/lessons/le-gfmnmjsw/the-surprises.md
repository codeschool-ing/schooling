---
title: The lines nobody expects
version: 1
---

People estimate the things they chose: the machines, the database, the storage. The lines that surprise
them are **the ones that came with the design without being chosen**, and the ones that keep growing
after everybody stopped looking. The estimate from the previous section already carries three of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The estimate of 298.64 USD a month drawn as one bar per line, longest first. Chosen in the design: 2 x t3.medium 98.11, load balancer hours 24.82, 2 x 30 GB gp3 9.12, S3 Standard 200 GB 8.10. Came with the design: 500 GB out 75.00, NAT gateway hours 67.89, 3 public IPv4 addresses 10.95, NAT gateway 50 GB 4.65. The lines that came with the design add up to 158.49, more than half of the bill.\"><defs><marker id=\"bill-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"14\" height=\"12\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chosen when the design was drawn</text><rect x=\"300\" y=\"16\" width=\"14\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"322\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">came with the design, unchosen</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2 x t3.medium</text><rect x=\"230\" y=\"48\" width=\"382.6\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620.6\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">98.11</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">500 GB out</text><rect x=\"230\" y=\"78\" width=\"292.5\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530.5\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">75.00</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">NAT gateway, hours</text><rect x=\"230\" y=\"108\" width=\"264.8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"502.8\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">67.89</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">load balancer, hours</text><rect x=\"230\" y=\"138\" width=\"96.8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"334.8\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">24.82</text><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3 public IPv4 addresses</text><rect x=\"230\" y=\"168\" width=\"42.7\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280.7\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.95</text><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2 x 30 GB gp3</text><rect x=\"230\" y=\"198\" width=\"35.6\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"273.6\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">9.12</text><text x=\"20\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">S3 Standard, 200 GB</text><rect x=\"230\" y=\"228\" width=\"31.6\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"269.6\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">8.10</text><text x=\"20\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">NAT gateway, 50 GB</text><rect x=\"230\" y=\"258\" width=\"18.1\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"256.1\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4.65</text><path d=\"M230 40 L230 282\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"20\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">total: 298.64 USD a month, before tax</text><text x=\"20\" y=\"322\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the marked lines: 158.49, more than half of the bill</text></svg>", "caption": "The estimate from the previous section, one bar per line. More than half of it, 158.49 of 298.64, is lines nobody chose: they arrived with a private subnet, a load balancer and users on the internet."}
```

## Data leaving

Traffic **into** the provider is free: the sheet's line `in from the internet` is 0.0000. Traffic **out**
to the internet costs 0.1500 per GB in São Paulo, once the account's first 100 GB of the month, which
are free, have gone. The asymmetry is deliberate, and it means that what a design sends to users is a
cost that grows with its success. A download page serving a 2 GB installer to 500 people a month sends
1,000 GB, which is 150.00 USD before the free 100 GB, more than both machines of the estimate together.

## The NAT gateway

A NAT gateway, from lesson 6, lets machines in private subnets reach out. **It is billed twice**: 0.0930
an hour for existing, which is the 67.89 in the estimate, and 0.0930 for every gigabyte it processes, in
either direction. The second charge comes on top of any data-out charge for the same bytes.

The expensive case is traffic that did not need to leave at all. If the machines read their 200 GB of
images from S3 through the NAT gateway, that is 18.60 USD a month in processing for traffic between two
services of the same provider in the same region. Lesson 6's **gateway endpoint for S3** routes that
traffic privately and carries no hourly or per-GB charge, so the same reads cost nothing extra.

## Public IPv4 addresses, in use or not

Since February 2024 AWS has charged for every public IPv4 address, including the ones attached to its
own load balancers and NAT gateways. The price list says so, in its own words:

```
ana@laptop:~/cloud$ vpc=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonVPC/20260917190528/sa-east-1/index.json
ana@laptop:~/cloud$ curl -s "$vpc" | jq -r '(.products[] | select(.attributes.usagetype | endswith("Address")) | .sku) as $s | .terms.OnDemand[$s][].priceDimensions[].description'
$0.005 per In-use public IPv4 address per hour
$0.005 per Idle public IPv4 address per hour
```

An address costs the same whether it is doing anything or not. At 0.0050 an hour, one address is 3.65
USD a month and **43.80 USD a year**: 0.0050 × 8,760 hours. That is small until you count them. An
Elastic IP address reserved for a machine that was later deleted keeps billing as idle, and so does
every address in a test account nobody opened since last year.

## What survives a deletion

Deleting a machine does not delete everything it used. A root volume created with the instance goes with
it by default, but **a volume attached afterwards survives the instance by default**, and so does every
snapshot ever taken. Nothing about a volume without a machine looks wrong in a list of volumes. A
forgotten 100 GB gp3 volume is 15.20 a month, which is 182.40 a year for a disk nobody can remember
attaching. Its snapshots are 0.0680 per GB-month on top, for as long as they exist.

## Traffic between zones

Lesson 9 put the two machines in two zones so that one could survive the other's failure. Traffic
between zones is billed at 0.0100 per GB **in each direction**: once leaving one zone and once entering
the other, so 0.02 for every gigabyte that crosses. A database replica in the second zone receiving 2 TB
of changes a month costs 40.00 for the crossing alone. It is the price of the availability lesson 9
bought, and it is right to pay it; it is wrong not to know it is there.

## Logs kept forever

A log group in CloudWatch Logs, AWS's log service, is created with its retention set to never expire, and
it keeps that until somebody changes it. Storage that nobody deletes is a line that grows every month without anybody deciding anything. An application writing 50 GB of logs a month into
S3 Standard stores 1,200 GB after two years, which costs 48.60 a month by then; the sum of those
twenty-four monthly bills is 607.50. **A retention rule is a cost decision**, written once, and lesson
5's lifecycle rules are how it is written for a bucket.

None of these lines is a trick. Each is on the price list, and each follows from a unit in the table at
the start of this lesson. What makes them surprises is that the design produced them without anybody
choosing them, which is why an estimate lists them and a monthly look at the bill checks them.
