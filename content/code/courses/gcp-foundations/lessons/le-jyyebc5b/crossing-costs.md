---
title: What it costs to cross a boundary
version: 1
---

**Inside Google Cloud, data is charged by the boundaries it crosses.** Into Google Cloud from the
internet is free. Between two machines in the same zone, over their internal addresses, is free.
Everything else has a price per gibibyte, and the price depends on **which boundary, and from
where**. This is the line on a bill that nobody predicted, because it is not attached to any machine:
it is attached to the arrows between them.

## The prices, and the day they were read

Google publishes its network prices on one public page, `cloud.google.com/vpc/network-pricing`,
which needs no account to read. Unlike AWS, it publishes no price file a program can download without
a key: the machine-readable catalogue, the Cloud Billing Catalog API, asks for an API key, and an API
key belongs to a project. So the numbers below were **read off that page on 30 October 2026**, and
they are the page's, not a program's. A price is a fact with a date on it; check the page before you
quote one to anybody.

| crossing | price per GiB, USD |
|---|---|
| between two VMs in the same zone, internal addresses | free |
| between two zones of one region | 0.01 |
| between two regions of North America | 0.02 |
| from a region in South America to any other region, Santiago included | 0.14 |
| into Google Cloud from the internet | free |

**The South America row is the surprise.** Every other continent charges less to stay at home than
to leave: North America to North America is 0.02, Europe to Europe 0.02. From São Paulo, the price is
0.14 wherever the data goes, whether to Santiago next door or to Iowa. For a design that replicates
between two South American regions, that is seven times what the same design costs in the United
States.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-crossings\" aria-label=\"What crossing each boundary costs, read off Google's network pricing page on 30 October 2026, in dollars per GiB. Inside southamerica-east1, two zones. Between two machines in the same zone, over internal addresses: free. Between the two zones: 0.01. From São Paulo to Santiago, southamerica-west1: 0.14. From São Paulo to Iowa, us-central1: also 0.14. From Iowa to South Carolina, us-east1, for comparison: 0.02. In from the internet: free.\"><defs><marker id=\"l01-crossings-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-crossings-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"300.0\" height=\"200.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"170.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">southamerica-east1</text><rect x=\"40.0\" y=\"78.0\" width=\"120.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">zone a</text><rect x=\"180.0\" y=\"78.0\" width=\"120.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">zone b</text><rect x=\"52.0\" y=\"126.0\" width=\"36.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">VM</text><rect x=\"112.0\" y=\"126.0\" width=\"36.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">VM</text><rect x=\"192.0\" y=\"126.0\" width=\"36.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">VM</text><path d=\"M88.0 140.0 L112.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"100.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">free</text><path d=\"M148.0 150.0 L192.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\" marker-start=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"170.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0.01</text><rect x=\"470.0\" y=\"40.0\" width=\"230.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"585.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">southamerica-west1 (Santiago)</text><rect x=\"470.0\" y=\"120.0\" width=\"230.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"585.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">us-central1 (Iowa)</text><path d=\"M322.0 100.0 L466.0 62.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"394.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0.14</text><path d=\"M322.0 140.0 L466.0 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"394.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0.14</text><rect x=\"470.0\" y=\"200.0\" width=\"230.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"585.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">us-east1 (South Carolina)</text><path d=\"M600.0 166.0 L600.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-paper-dim)\"></path><text x=\"612.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.02</text><text x=\"170.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">in from the internet: free</text><text x=\"585.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">USD per GiB, read 30 October 2026</text></svg>", "caption": "From São Paulo, the next region costs as much as the next continent."}
```

Internet traffic out has a table of its own, priced by the region the data leaves and the continent
it arrives in, with a lower **Standard Tier** for traffic that may travel the public internet instead
of Google's backbone. The page draws that table per region, behind a selector, and this course quotes
no number from it.

## A program that does the arithmetic

The program below holds the four prices from the table and turns a monthly volume into a monthly
bill. It is the kind of thing worth keeping beside a design document: when somebody asks what
spreading a system over two regions costs, the answer is one command. Save it as `~/gcp/cost.py`.

```schooling-example
{"language": "python", "file": "cost.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"What a month of traffic across one boundary costs, at prices read by hand.\n\n    python3 cost.py GIB CROSSING\n\nCROSSING is zone, region, continent or us-region. The prices were read off\ncloud.google.com/vpc/network-pricing on 2026-10-30, in USD per GiB.\n\"\"\"\nimport sys\n\n", "note": "What the program is for, and where its numbers come from. The date is part of the price: a number with no date cannot be checked against the page."}, {"code": "READ_ON = '2026-10-30'\nPRICES = {\n    'zone': ('between two zones of southamerica-east1', 0.01),\n    'region': ('southamerica-east1 to southamerica-west1', 0.14),\n    'continent': ('southamerica-east1 to us-central1', 0.14),\n    'us-region': ('us-central1 to us-east1', 0.02),\n}\n\n", "note": "Four crossings, each with the sentence that says which arrow it is. The last one is there for comparison: the same kind of crossing, on another continent."}, {"code": "gib, crossing = float(sys.argv[1]), sys.argv[2]\nwhat, price = PRICES[crossing]\nprint(f'{gib:,.0f} GiB {what}')\nprint(f'  {price:.2f} USD per GiB, read {READ_ON}')\nprint(f'  {gib * price:,.2f} USD a month')\n", "note": "The arithmetic is one multiplication. What the program adds is that nobody does it from memory, and that the date travels with the answer."}]}
```

A team sends 500 GiB a month between the parts of a system. Here is that volume across each boundary:

```
ana@laptop:~/gcp$ python3 cost.py 500 zone
500 GiB between two zones of southamerica-east1
  0.01 USD per GiB, read 2026-10-30
  5.00 USD a month
ana@laptop:~/gcp$ python3 cost.py 500 region
500 GiB southamerica-east1 to southamerica-west1
  0.14 USD per GiB, read 2026-10-30
  70.00 USD a month
ana@laptop:~/gcp$ python3 cost.py 500 continent
500 GiB southamerica-east1 to us-central1
  0.14 USD per GiB, read 2026-10-30
  70.00 USD a month
ana@laptop:~/gcp$ python3 cost.py 500 us-region
500 GiB us-central1 to us-east1
  0.02 USD per GiB, read 2026-10-30
  10.00 USD a month
```

The same 500 GiB costs **5 dollars a month between two zones and 70 between two regions**, and
moving the second region from Santiago to Iowa changes nothing. Across two regions in the United
States it would cost 10. These are the numbers to bring to the conversation about whether a system
needs a second region, and they say that in São Paulo the question is a more expensive one to answer
with yes.

**What the program does not know** is everything the page charges besides the crossing: the machine
that sends the data, the load balancer it passes through, the NAT gateway of lesson 17. Each has a
price of its own, and lesson 13 reads a bill where they appear together.
