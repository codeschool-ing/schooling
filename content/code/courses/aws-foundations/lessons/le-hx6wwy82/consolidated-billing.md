---
title: One bill, and the volume prices it adds up to
version: 1
---

**The management account pays for the whole organisation, and AWS prices the organisation as if it
were one account.** The wrong picture is an envelope: six bills stapled together and sent to one
address, each priced as though the others did not exist. The first half of that is true. Each member's
charges still appear under its own account number. The second half is not, and where a price has
tiers, the difference is money.

## One payer

**Consolidated billing** is the part of Organizations that every organisation has, whatever its
feature set. The management account is the **payer**: it holds the payment method, receives the
invoice and pays it. The members are listed on that invoice one by one, with what each of them used,
so "what did `shop-staging` cost in September" is a line rather than an estimate. An account created
inside the organisation has no card of its own, and lesson 2 said it costs nothing to have.

## Volume tiers are counted across the organisation

Some prices fall as the month's usage grows. Lesson 1 printed one of them, data sent from São Paulo
to the internet; here it is again from the same list:

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-DataTransfer-Out-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
SAE1-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.1500
     10,240 to    51,200 GB   0.1380
     51,200 to   153,600 GB   0.1260
    153,600 to       Inf GB   0.1140
```

The first 10,240 GB of a month cost 0.15 per GB, and the next ones 0.138. **For the tiers, AWS adds
up the usage of every account in the organisation before it prices any of it.** That is AWS's
documented rule for consolidated billing, and its own explanation uses a data-transfer tier as the example.

Suppose `shop-prod` and `shop-staging` each send 8 TB, 8,192 GB, to the internet in a month:

| | gigabytes at 0.15 | gigabytes at 0.138 | dollars |
|---|---|---|---|
| two separate accounts, each | 8,192 | 0 | 1,228.80 |
| two separate accounts, together | 16,384 | 0 | **2,457.60** |
| one organisation | 10,240 | 6,144 | **2,383.87** |

Apart, neither account ever leaves the first tier. Together they cross it at 10,240 GB, and the
6,144 GB beyond it cost 0.138: 1,536.00 plus 847.87. **The organisation saves 73.73 dollars that
month for no change at all in what was sent.** The arithmetic leaves out the 100 GB a month that AWS
gives away, which lesson 1 said is on AWS's pricing page and not in these lines. How the saving is
shown against each account is a detail of the bill's layout; the second total is what is paid.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-pooling\" aria-label=\"Two accounts each send 8,192 GB to the internet from São Paulo in a month. Billed apart, each stays inside the first tier, 10,240 GB at 0.15 dollars per GB, and the two pay 2,457.60 together. In one organisation the 16,384 GB are priced as one: 10,240 GB at 0.15 and 6,144 GB at 0.138, 2,383.87 in all. Price list of 16 September 2026.\"><path d=\"M431.2 46.0 L431.2 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M431.2 98.0 L431.2 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M431.2 190.0 L431.2 232.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"431.2\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the first tier ends at 10,240 GB</text><text x=\"140.0\" y=\"78.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">billed apart</text><rect x=\"150.0\" y=\"60.0\" width=\"224.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"262.5\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shop-prod: 8,192 at 0.15</text><rect x=\"376.0\" y=\"60.0\" width=\"224.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"487.5\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shop-staging: 8,192 at 0.15</text><text x=\"612.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2,457.60</text><text x=\"140.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one organisation</text><rect x=\"150.0\" y=\"152.0\" width=\"280.2\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"290.6\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10,240 at 0.15</text><rect x=\"432.2\" y=\"152.0\" width=\"167.8\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"515.6\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6,144 at 0.138</text><text x=\"612.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2,383.87</text><path d=\"M150.0 240.0 L600.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150.0 236.0 L150.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"150.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M375.0 236.0 L375.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"375.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8,192</text><path d=\"M431.2 236.0 L431.2 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"431.2\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10,240</text><path d=\"M600.0 236.0 L600.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"600.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16,384</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">gigabytes in a month, dollars per gigabyte, price list of 16 September 2026</text></svg>", "caption": "The same 16,384 GB, priced apart and priced together."}
```

## Discounts and credits travel too

Two more things cross the walls on the bill, and lesson 14 reads both of them on one.

**Reserved Instances and Savings Plans are shared across the organisation.** Both are a commitment
to a certain amount of use in exchange for a lower price, and by default the discount applies to
matching use in any account of the organisation, not only the one that bought it. Lesson 14 reads
them on a bill; here the point is that the tree decides who benefits. The sharing can be switched
off for an account in the management account's billing preferences.

**Credits are shared as well.** AWS sometimes grants credits, for a programme, a migration or a
mistake on its side, and by default they are spent against the whole organisation's bill. The
same billing preferences can restrict that.

## Two feature sets

An organisation is created with one of two feature sets, and the transcript's `ALL` was the default:

- **`ALL`**, all features: consolidated billing plus the policies that lessons 4 and 5 use, service
  control policies first, and the integration with other AWS services that lets one account run a
  service for the whole tree.
- **`CONSOLIDATED_BILLING`**: the bill and nothing else. No policies of any kind can be attached.

**There is no reason to start with billing alone.** It exists for organisations that existed before
the policies did, and for a company that only wants one invoice. Moving from billing alone to all
features is possible, and the API reference for `EnableAllFeatures` says what it costs: every
**invited** account has to approve the change before it takes effect, so a large organisation waits
on its slowest administrator. Going back is not offered.

## What moto has of this

**moto has no bill.** It keeps no usage and computes no charge, and Cost Explorer, the service
lesson 13 uses to read costs, answers moto's empty organisation with nothing:

```
ana@laptop:~/aws$ aws ce get-cost-and-usage --time-period Start=2026-09-01,End=2026-10-01 --granularity MONTHLY --metrics UnblendedCost --group-by Type=DIMENSION,Key=LINKED_ACCOUNT
{
    "ResultsByTime": [],
    "DimensionValueAttributes": []
}
```

So everything in this section about money is AWS's documented behaviour and **was not run**. The
prices are not from memory: they come from the price list AWS published on **16 September 2026**,
read by the program from lesson 1, and the arithmetic is the table's.
