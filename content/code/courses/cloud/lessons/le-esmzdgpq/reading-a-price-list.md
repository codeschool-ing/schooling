---
title: Reading a price list
version: 2
---

Every provider in this lesson publishes prices, and they publish them differently. **AWS publishes
its whole price list as JSON files that anyone can download, with no account and no key.** Azure
has a public retail-price API of its own, and the others publish their prices on web pages. This
course pinned only AWS's list, which is why every price in it is an AWS price; the other providers'
pages were not captured, and comparing them is your exercise at the end of this section.

The list starts at one index:

```
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json | jq '.offers | length'
272
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json | jq -r '.publicationDate'
2026-09-28T18:21:50Z
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json | jq -r '.offers | keys[]' | grep -E '^(AmazonEC2|AmazonS3|AWSLambda)$'
AWSLambda
AmazonEC2
AmazonS3
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json | jq '.offers.AWSLambda'
{
  "offerCode": "AWSLambda",
  "versionIndexUrl": "/offers/v1.0/aws/AWSLambda/index.json",
  "currentVersionUrl": "/offers/v1.0/aws/AWSLambda/current/index.json",
  "currentRegionIndexUrl": "/offers/v1.0/aws/AWSLambda/current/region_index.json",
  "savingsPlanVersionIndexUrl": "/savingsPlan/v1.0/aws/AWSComputeSavingsPlan/current/index.json",
  "currentSavingsPlanIndexUrl": "/savingsPlan/v1.0/aws/AWSComputeSavingsPlan/current/region_index.json"
}
```

The index names 272 offers, one per priced service, on the day it was read, and it carries the
moment it was generated. The three names this course uses are among them, spelt as the index spells
them. Each offer entry is a set of addresses: a list of every version ever published, the current
version, and the current version split by region.

## Four files deep

The addresses lead to a small tree. A price is four files below the index:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Four boxes joined by arrows, left to right. index.json, one entry per service, 272 offers on the day of the capture. AWSLambda/, one offer, which keeps every version. 20260919002359/, one version, frozen once published. sa-east-1/index.json, one region, with 389 products for Lambda. The region file splits into products, what is sold, and terms, the price of each product. A note says that prices.py pins the version.\"><defs><marker id=\"plst-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"152\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"96\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">index.json</text><text x=\"96\" y=\"80.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one entry</text><text x=\"96\" y=\"91.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">per service</text><path d=\"M173 72 L194 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#plst-ah)\"></path><rect x=\"196\" y=\"30\" width=\"152\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"272\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">AWSLambda/</text><text x=\"272\" y=\"80.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one offer, which</text><text x=\"272\" y=\"91.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">keeps every version</text><path d=\"M349 72 L370 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#plst-ah)\"></path><rect x=\"372\" y=\"30\" width=\"152\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">20260919002359/</text><text x=\"448\" y=\"80.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one version,</text><text x=\"448\" y=\"91.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">frozen once published</text><path d=\"M525 72 L546 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#plst-ah)\"></path><rect x=\"548\" y=\"30\" width=\"152\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">sa-east-1/index.json</text><text x=\"624\" y=\"80.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one region</text><text x=\"624\" y=\"91.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">of that version</text><text x=\"96\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">272 offers that day</text><text x=\"624\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">389 products for Lambda</text><rect x=\"372\" y=\"160\" width=\"160\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"452\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">products</text><text x=\"452\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what is sold</text><rect x=\"548\" y=\"160\" width=\"152\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"624\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">terms</text><text x=\"624\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the price of each</text><path d=\"M624 146 L624 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M600 146 L452 146 L452 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">prices.py pins this</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">step, so its sheet holds still</text><path d=\"M200 180 L410 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#plst-ah)\"></path></svg>", "caption": "Four files deep from the index to a price. The current version moves whenever AWS publishes; a pinned version does not, which is why the course sheet names one."}
```

The word **current** in those addresses is the trap. The current version changes whenever AWS
publishes a new one, so a script that reads `current` prints different numbers next month and
cannot say why. The course's `prices.py` reads one pinned version of each offer instead. That is
why the sheet prints its versions at the top: **a price without the version it came from cannot be
checked by anybody.**

How much is in one region's file depends on the service. The EC2 file is too big to fetch twice, so
the second command reads the copy the price sheet keeps in its cache, from its first `ec2` run in
lesson 1:

```
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSLambda/20260919002359/sa-east-1/index.json | jq '.products | length'
389
ana@laptop:~/cloud$ jq '.products | length' ~/.cache/cloud-prices/AmazonEC2-20260925174521-sa-east-1.json
65165
```

Lambda has 389 products in São Paulo. EC2 has 65,165, because every machine size is a product
several times over: per operating system, per licence model, per kind of tenancy. That count is
what "a price list with tens of thousands of lines" meant earlier in this lesson, and it is for one
service in one region.

## Two lines of the sheet

`prices.py` reads those files and prints the few lines the course uses. The EC2 block, from the
course directory:

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
ana@laptop:~/cloud$ python3 -c 'print(round(0.16065 / 0.10080, 2))'
1.59
```

The sheet is the public list for `sa-east-1` (São Paulo) and `us-east-1` (Northern Virginia), in
US dollars, excluding tax, at the offer versions it prints. Read one line across: `m7i.large`, two
virtual processors and 8 GiB of memory, costs `0.16065` USD an hour in São Paulo and `0.10080` in
Virginia. **The same machine, from the same provider, is 1.59 times the price in São Paulo.** The
other lines agree roughly: `t3.micro` is `0.01680` against `0.01040`, which is 1.62.

An hourly price is hard to feel, so turn it into a month. The program below does the arithmetic in
the open, and it is the one to extend when you compare providers:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "HOURS = 730  # 24 * 365 / 12\n\n",
      "note": "A month in hours: 24 × 365 / 12 is 730. A price list quotes by the hour and a budget is written by the month, so this is the bridge between them."
    },
    {
      "code": "m7i_large = {  # USD per hour, Linux, on demand\n    'sa-east-1': 0.16065,\n    'us-east-1': 0.10080,\n}\n\n",
      "note": "Two lines of the sheet, copied with every digit it printed. Rounding here is how a comparison drifts away from its source. When you compare providers, this is where their prices go, each with the date you read it."
    },
    {
      "code": "for region, hourly in m7i_large.items():\n    print(f'{region}  {hourly * HOURS:7.2f} USD a month')\n\n",
      "note": "Hourly price times the hours in a month: the machine running all month, which is what a server does."
    },
    {
      "code": "print(f'ratio      {m7i_large[\"sa-east-1\"] / m7i_large[\"us-east-1\"]:.2f}')\n",
      "note": "The ratio says the same thing as the two amounts, in one number that does not depend on how long the machine runs."
    }
  ],
  "output": "sa-east-1   117.27 USD a month\nus-east-1    73.58 USD a month\nratio      1.59\n"
}
```

A machine that runs all month in São Paulo is `117.27` USD at list price, and `73.58` in Virginia.
That difference is real, and it is also only one line. Lesson 9 is about what the distance to
Virginia costs a user in Brazil, which is the other side of the same choice.

## What the list does not tell you

A price list is the starting point of a bill, not the bill. It leaves out three things:

- Discounts. The sheet carries reserved prices beside the on-demand ones, and large customers
  negotiate their own. Lesson 10 is about both.
- Free tiers. Some services give an amount away every month, and the Lambda block of the sheet
  lists its own.
- The shape of the bill. A machine arrives with a disk, an address and the data it sends, each
  priced on its own line of the sheet. The machine's hourly price is usually the largest line and
  never the only one.

## Your exercise

To compare with the providers whose pages this course did not capture, use the same method:

1. choose one machine shape, such as 2 vCPU and 8 GiB, and one region per provider;
2. write down each price with the date you read it and the page it came from;
3. bring every price to the same unit, per hour or per 730-hour month;
4. note what the price includes: the disk, the public address, a transfer allowance;
5. compare the total for what your application needs, not the machine line alone.

Step 4 is where the smaller providers make their case, and step 5 is where the comparison stops
being about one number.
