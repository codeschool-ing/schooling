---
title: Three prices for the same gigabyte
version: 1
---

Put the three kinds side by side and the price of a gigabyte differs by a factor of fourteen. These
are the sheet's storage lines, read from the AWS public price list for `sa-east-1` (São Paulo) and
`us-east-1` (N. Virginia), in USD, excluding tax, at the offer versions it prints:

```
ana@laptop:~/cloud$ python3 prices.py storage
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

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
```

The block price is the `gp3` line from the block section's capture, 0.1520 and 0.0800. The S3 line
is the first tier, which covers the first 50 TB stored in a month. Keeping **500 GB for one month**
in São Paulo in each of the three:

| | line | 500 GB for a month, `sa-east-1` | `us-east-1` |
|---|---|---|---|
| block | EBS `gp3` | 500 × 0.1520 = 76.00 | 500 × 0.0800 = 40.00 |
| file | EFS Standard | 500 × 0.5700 = 285.00 | 500 × 0.3000 = 150.00 |
| object | S3 Standard | 500 × 0.04050 = 20.25 | 500 × 0.02300 = 11.50 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"What 500 GB kept for one month costs at the AWS public list price, in USD, for three kinds of storage. EBS gp3, block: 76.00 in sa-east-1 and 40.00 in us-east-1. EFS Standard, file: 285.00 in sa-east-1 and 150.00 in us-east-1. S3 Standard, object: 20.25 in sa-east-1 and 11.50 in us-east-1.\"><defs><marker id=\"bars-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">500 GB for one month, USD, AWS public list price</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">EBS gp3</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">block</text><rect x=\"170\" y=\"50\" width=\"117.33333333333333\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"295.3333333333333\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">76.00</text><rect x=\"170\" y=\"72\" width=\"61.754385964912274\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"239.75438596491227\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">40.00</text><text x=\"20\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">EFS Standard</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">file</text><rect x=\"170\" y=\"120\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">285.00</text><rect x=\"170\" y=\"142\" width=\"231.57894736842104\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"409.57894736842104\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">150.00</text><text x=\"20\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">S3 Standard</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">object</text><rect x=\"170\" y=\"190\" width=\"31.26315789473684\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"209.26315789473685\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20.25</text><rect x=\"170\" y=\"212\" width=\"17.75438596491228\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"195.75438596491227\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">11.50</text><rect x=\"170\" y=\"256\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"188\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sa-east-1</text><rect x=\"280\" y=\"256\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"298\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">us-east-1</text></svg>", "caption": "The same 500 GB, three prices. File storage costs fourteen times what object storage does in the same region, and each of them costs nearly twice as much in São Paulo as in N. Virginia."}
```

## What each price buys

Each is the price of a different thing, and the table only compares them fairly once you know what
each one includes.

**The volume price buys reserved capacity with performance attached.** Five hundred gigabytes of
SSD are yours, with 3,000 IOPS, whether you use them or not, in one zone. Fill 40 GB of it and you
still pay 76.00.

**The file price buys a filesystem somebody runs across several zones, charged on what it holds.**
That changes the comparison more than the bar chart suggests. The same 40 GB on EFS is
40 × 0.5700 = 22.80, less than the mostly empty volume. The file service is dear per gigabyte
stored and cheap for a small amount, and the volume is the reverse.

**The object price buys the least and charges for the rest separately.** No filesystem, no mount,
and a first byte that arrives more slowly than from a local volume. What you get for 0.04050 is
capacity charged on what is stored, kept in several zones. Requests are billed on their own: the
sheet prices `PUT, COPY, POST, LIST` at 0.00700 per 1,000 in São Paulo, so a million uploads cost
7.00, and a million `GET`s at 0.00056 per 1,000 cost 0.56. For data served to the public, the line
that dominates is transfer out to the internet, which lesson 10 prices.

The column on the right is the other lesson in the sheet. Each of the three lines costs between
1.76 and 1.9 times as much in São Paulo as in N. Virginia: 0.04050 / 0.02300 is 1.76, and 0.1520 / 0.0800 and
0.5700 / 0.3000 are both 1.9. Where the data may live is a question with a price on it, and lesson
9 weighs that price against the distance to the people reading it.
