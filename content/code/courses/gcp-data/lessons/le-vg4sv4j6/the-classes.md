---
title: What a storage class trades
version: 1
---

**A storage class is a price for keeping a gibibyte paired with a price for reading it back**, and
every class below Standard buys a lower first price with a higher second one. The names suggest a
warehouse with a cold room at the back, where the cheap shelves are slow and an archived file has to
be fetched before anybody can open it. Cloud Storage does not work like that. All four classes answer
the first byte in milliseconds, through the same API, with the same commands. What changes is the
bill: for keeping, for reading, and for leaving before a minimum number of days.

Every class is chosen per object, not per bucket. One bucket can hold today's orders in Standard,
last year's in Coldline and the 2019 audit exports in Archive, side by side under the same prefixes.
A bucket has a default class, which the next section shows, and it is only what an object gets when
nobody asks for anything else.

This lesson, like every lesson of the course, assumes fake-gcs-server running in its own terminal and
the lines of lesson 1's "Every time you open a terminal" typed in this one.

## The prices

Google's pricing page for Cloud Storage, cloud.google.com/storage/pricing, read on 2026-10-30, gives
these numbers for a bucket in a single region, in USD. The storage price is São Paulo's,
`southamerica-east1`; the retrieval fees and the operation prices on that page are the same for every
single region.

| class | keeping, per GiB-month | reading back, per GiB | minimum stay | Class A, per 1,000 | Class B, per 1,000 |
|---|---|---|---|---|---|
| Standard | 0.035 | none | none | 0.005 | 0.0004 |
| Nearline | 0.020 | 0.01 | 30 days | 0.01 | 0.001 |
| Coldline | 0.007 | 0.02 | 90 days | 0.02 | 0.01 |
| Archive | 0.003 | 0.05 | 365 days | 0.05 | 0.05 |

**Standard costs 0.035 a GiB-month and Archive 0.003**, so the archive keeps a gibibyte for less
than a tenth of the price. The retrieval column is the other half: reading a gibibyte back costs
nothing extra from Standard and 0.05 from Archive, which is more than a year of keeping it there.

Class A operations are the ones that write or list: an upload, a copy, a rewrite, a listing. Class B
are the ones that read: a download, a `describe`. Both are priced per thousand requests and by the
class of the object they touch, so a million small files in Archive cost 50 USD to write and another
50 to read once, whatever their size. Lesson 5 is where requests and network are priced in full.

```
ana@laptop:~/gcp$ python3 -c 'print(round(0.035 / 0.003, 1), round(1024 * 0.003 * 365 / 30, 2), round(1024 * 0.003 * 10 / 30, 2))'
11.7 37.38 1.02
```

The first number is the ratio, Standard over Archive, 11.7. The other two are the minimum stay at
work, and they are the next paragraph.

**The minimum stay is a bill for leaving early.** An object deleted, replaced or rewritten into
another class before its minimum is charged as if it had stayed the whole minimum. A tebibyte, 1,024
GiB, kept in Archive for ten days would cost 1,024 × 0.003 × 10 / 30 = 1.02 USD; deleted on the tenth
day it is billed for all 365, which with a month counted as 30 days is 1,024 × 0.003 × 365 / 30 =
37.38. The pricing page names three cases
where the charge does not apply: an object in Standard, a class changed by a life-cycle rule, and
an object in a bucket with Autoclass on. Lesson 3 writes the rule, and this lesson's section on
Autoclass shows the bucket.

**There is no smallest billed size.** A 10 KB object in Archive is billed as 10 KB. What makes small
objects expensive in the colder classes is the request price, because the request costs the same
for 10 KB as for 10 GB.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Four Cloud Storage classes on two axes, with São Paulo prices. Across, the price of keeping a GiB for a month; up, the fee for reading a GiB back. Standard at 0.035 with no fee and no minimum; Nearline at 0.020, 0.01 a GiB read, 30 days minimum; Coldline at 0.007, 0.02 a GiB, 90 days; Archive at 0.003, 0.05 a GiB, 365 days. Every class answers in milliseconds: the cheaper the shelf, the dearer the read and the longer the stay that is billed.\" data-fig=\"l02-classes\"><path d=\"M150.0 270.0 L690.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150.0 270.0 L150.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"150.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M280.0 270.0 L280.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"280.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.01</text><path d=\"M410.0 270.0 L410.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"410.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.02</text><path d=\"M540.0 270.0 L540.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"540.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.03</text><path d=\"M670.0 270.0 L670.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"670.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.04</text><text x=\"690.0\" y=\"306.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">keeping, USD per GiB-month</text><path d=\"M150.0 50.0 L150.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M145.0 270.0 L150.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M145.0 228.0 L150.0 228.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"228.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.01</text><path d=\"M150.0 228.0 L690.0 228.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M145.0 186.0 L150.0 186.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.02</text><path d=\"M150.0 186.0 L690.0 186.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M145.0 144.0 L150.0 144.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.03</text><path d=\"M150.0 144.0 L690.0 144.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M145.0 102.0 L150.0 102.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.04</text><path d=\"M150.0 102.0 L690.0 102.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M145.0 60.0 L150.0 60.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.05</text><path d=\"M150.0 60.0 L690.0 60.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">reading back, USD per GiB</text><circle cx=\"605.0\" cy=\"270.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"605.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard</text><text x=\"605.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">no minimum</text><circle cx=\"410.0\" cy=\"228.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"418.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Nearline</text><text x=\"418.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">minimum 30 days</text><circle cx=\"241.0\" cy=\"186.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"249.0\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Coldline</text><text x=\"249.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">minimum 90 days</text><circle cx=\"189.0\" cy=\"60.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"197.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Archive</text><text x=\"197.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">minimum 365 days</text></svg>", "caption": "What a GiB costs to keep in São Paulo, against what it costs to read back, and the stay each class bills at least. The first byte arrives in milliseconds in all four."}
```

## Choosing by the question the data answers

Google's documentation puts the choice as a frequency, and it is a good first cut. **Nearline is for
data read less than once a month, Coldline for less than once a quarter, Archive for less than once a
year**, and Standard for everything read more often, or kept for too short a time to pay any minimum.
The frequencies line up with the minimum stays on purpose: a class whose data is read once a quarter
will not usually be deleted inside its 90 days either.

The frequency is a rule of thumb and the bill is arithmetic, and they can disagree. A tebibyte read in
full every month is "read once a month", which the rule puts in Nearline, and the last section of this
lesson shows Coldline costing less for it in São Paulo. What the rule gets right is the order of
questions to ask: how often is this read, how much of it is read each time, and how long is it kept.
The first two decide the retrieval fees and the requests, and the third decides whether a minimum stay
is ever paid for nothing.

## What else differs, and what does not

Google's page on storage classes, cloud.google.com/storage/docs/storage-classes, states the rest,
and none of it is something fake-gcs-server can show, because the emulator keeps every object in the
same memory whatever its class says:

- **durability is the same in all four**, eleven nines a year by design. A colder class does not
  keep fewer copies;
- **availability is lower in the three colder ones**: the page gives 99.99% typical monthly
  availability for Standard in a region and 99.9% for Nearline, Coldline and Archive, and the
  service level agreement promises less for them as well;
- **latency and throughput are the same**. An Archive object streams at the speed a Standard one
  does.

Two more names turn up in the documentation and the API, and this course does not use them. **Rapid
storage** is a class for zonal buckets, built for very low latency next to a compute cluster, and it
appears on the pricing page beside the four. `MULTI_REGIONAL`, `REGIONAL` and
`DURABLE_REDUCED_AVAILABILITY` are older names that the API still accepts and that Google no longer
recommends; an old bucket may report one of them.
