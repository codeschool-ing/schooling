---
title: What it costs to cross a boundary
version: 1
---

**Inside AWS, data is charged by the boundaries it crosses.** Into AWS from the internet is free.
Between two machines in the same zone, over their private addresses, is free. Everything else has a
price per gigabyte, and the price depends on **which boundary, and in which direction**. This is the
line on a bill that nobody predicted, because it is not attached to any machine: it is attached to
the arrows between them.

## A price list you can read without an account

AWS publishes every price it charges as JSON files, one per service and region, at addresses that
need no account and no key. Each file is an **offer**, and AWS keeps every version it ever
published, so a version number pins a price list the way a version number pins a program. The
program below reads one offer and prints the lines you name. Save it as `~/aws/price.py`; later
lessons use it for other services.

```schooling-example
{"language": "python", "file": "price.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Reads lines of the AWS public price list, with no account and no key.\n\n    python3 price.py OFFER VERSION REGION USAGETYPE...\n\nOFFER is a service's code in the list (AWSDataTransfer, AmazonEC2, ...),\nVERSION one of the versions AWS keeps of it, so the answer never moves, and\neach USAGETYPE a line of that offer's bill. The file is downloaded once into\n~/.cache/aws-prices and read from there afterwards.\n\"\"\"\n", "note": "What the program is for, and how to call it. The three arguments before the usage types are what make an answer repeatable: the same offer, at the same version, for the same region, always prints the same prices."}, {"code": "import json\nimport os\nimport sys\nimport urllib.request\n\n", "note": "Only Python's own library. Nothing to install, and nothing that needs the virtual environment."}, {"code": "BASE = 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws'\nCACHE = os.path.expanduser('~/.cache/aws-prices')\n\n\n", "note": "Where the price list lives, and where the program keeps what it downloaded. The address is public: there is no account in it, and no key."}, {"code": "def offer(code, version, region):\n    os.makedirs(CACHE, exist_ok=True)\n    path = os.path.join(CACHE, f'{code}-{version}-{region}.json')\n    if not os.path.exists(path):\n        url = f'{BASE}/{code}/{version}/{region}/index.json'\n        urllib.request.urlretrieve(url, path + '.part')\n        os.rename(path + '.part', path)\n    with open(path) as f:\n        return json.load(f)\n\n\n", "note": "Fetches one offer at one version, once. It writes to a file ending in `.part` and renames it only when the download is complete, so a broken download is never mistaken for a finished one."}, {"code": "def main():\n    code, version, region, *usages = sys.argv[1:]\n    doc = offer(code, version, region)\n    print(f'{code} {doc[\"version\"]}, published {doc[\"publicationDate\"][:10]}, USD')\n", "note": "The arguments, and the header line: which offer, which version, and the day AWS published it. That date is the one a lesson quotes beside a price."}, {"code": "    for usage in usages:\n        found = []\n        for sku, product in doc['products'].items():\n            if product['attributes'].get('usagetype') != usage:\n                continue\n            for term in doc['terms']['OnDemand'].get(sku, {}).values():\n                for d in term['priceDimensions'].values():\n                    found.append((float(d['beginRange']), d['endRange'],\n                                  d['pricePerUnit']['USD'], d['unit']))\n", "note": "An offer is a list of products, each with a usage type, and a separate list of terms that price them. This walks both and keeps every price for the usage type asked for. On-demand is the term with no commitment; lesson 14 reads the others."}, {"code": "        print(usage)\n        if not found:\n            print('  not in this offer')\n        for begin, end, price, unit in sorted(found):\n            end = end if end == 'Inf' else f'{float(end):,.0f}'\n            print(f'  {begin:>9,.0f} to {end:>9} {unit:<4} {float(price):.4f}')\n\n\nmain()\n", "note": "A usage type can have several tiers, each a range of gigabytes or hours with its own price. They are printed in order, from the first unit of the month."}]}
```

A **usage type** is the name a bill gives to one kind of consumption, such as gigabytes sent from
São Paulo to Virginia. Each region prefixes its own, `SAE1-` for São Paulo; `us-east-1`, the oldest
region, mostly has no prefix at all. Run it for São Paulo:

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-DataTransfer-Regional-Bytes SAE1-USE1-AWS-Out-Bytes SAE1-DataTransfer-Out-Bytes SAE1-DataTransfer-In-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
SAE1-DataTransfer-Regional-Bytes
          0 to       Inf GB   0.0100
SAE1-USE1-AWS-Out-Bytes
          0 to       Inf GB   0.1380
SAE1-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.1500
     10,240 to    51,200 GB   0.1380
     51,200 to   153,600 GB   0.1260
    153,600 to       Inf GB   0.1140
SAE1-DataTransfer-In-Bytes
          0 to       Inf GB   0.0000
```

And for the same crossings, starting from Virginia:

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 us-east-1 USE1-SAE1-AWS-Out-Bytes DataTransfer-Out-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
USE1-SAE1-AWS-Out-Bytes
          0 to       Inf GB   0.0200
DataTransfer-Out-Bytes
          0 to    10,240 GB   0.0900
     10,240 to    51,200 GB   0.0850
     51,200 to   153,600 GB   0.0700
    153,600 to       Inf GB   0.0500
ana@laptop:~/aws$ ls ~/.cache/aws-prices
AWSDataTransfer-20260916132208-sa-east-1.json
AWSDataTransfer-20260916132208-us-east-1.json
```

These are the prices in the list AWS published on **16 September 2026**, in dollars and before tax.

## Reading the four lines

| crossing | from São Paulo | from Virginia |
|---|---|---|
| between two zones of the region | 0.0100 per GB, **each way** | 0.0100 per GB, each way |
| to the other region | 0.1380 per GB | 0.0200 per GB |
| out to the internet, first 10 TB of a month | 0.1500 per GB | 0.0900 per GB |
| in from the internet | free | free |

**Between zones is charged on both sides.** The usage type is one line, and AWS's documentation
says it is billed on the data leaving one zone *and* on the data arriving in the other, so a
gigabyte that crosses costs 0.02 in total. A database replicating 500 GB a month to a standby in
the next zone costs 500 × 0.02 = **10 dollars a month in transfer alone**, before either machine.

**Between regions, the direction decides.** A gigabyte leaving São Paulo for Virginia costs 0.138;
the same gigabyte leaving Virginia for São Paulo costs 0.02, almost seven times less. A nightly copy
of 2 TB of backups from `sa-east-1` to `us-east-1` is 2,048 × 0.138 = **282.62 dollars a month**;
the copy in the other direction would be 40.96. That is not a quirk to work around; it is the price
of carrying the bytes over a long and expensive path, and it is what you weigh when you decide where
the copy of something lives.

**To the internet, the tiers fall with volume**, and São Paulo starts dearer than Virginia: 0.15
against 0.09 for the first 10 TB of the month. What the four lines do not show is that AWS gives
away the first 100 GB a month sent to the internet, summed over every region of an account; that
allowance is on AWS's pricing page rather than in these lines, so it was read there and not printed
by the program.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" data-fig=\"l01-crossings\" aria-label=\"What crossing each boundary costs, from the price list of 16 September 2026, in dollars per gigabyte. Inside the São Paulo region, sa-east-1, two Availability Zones. Between two machines in the same zone: free. Between the two zones: 0.01 each way. From São Paulo to Virginia, us-east-1: 0.138. From Virginia to São Paulo: 0.02. From São Paulo out to the internet: 0.15 for the first 10 TB of a month. In from the internet: free.\"><defs><marker id=\"l01-crossings-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-crossings-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"430.0\" height=\"240.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"45.0\" y=\"80.0\" width=\"180.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1a</text><rect x=\"250.0\" y=\"80.0\" width=\"180.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1b</text><rect x=\"58.0\" y=\"130.0\" width=\"52.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"160.0\" y=\"130.0\" width=\"52.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M112.0 147.0 L158.0 147.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-phosphor)\" marker-start=\"url(#l01-crossings-af-ah-phosphor)\"></path><text x=\"135.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">same zone: free</text><rect x=\"310.0\" y=\"130.0\" width=\"60.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M214.0 147.0 L308.0 147.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\" marker-start=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"340.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">between zones:</text><text x=\"340.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">0.01 each way</text><rect x=\"520.0\" y=\"40.0\" width=\"180.0\" height=\"110.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"536.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">us-east-1</text><rect x=\"580.0\" y=\"85.0\" width=\"60.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M372.0 140.0 L432.0 127.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M432.0 127.0 L577.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"476.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">0.138</text><path d=\"M577.0 112.0 L432.0 145.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M432.0 145.0 L374.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-phosphor)\"></path><text x=\"486.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">0.02</text><rect x=\"130.0\" y=\"330.0\" width=\"210.0\" height=\"56.0\" rx=\"26\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"358.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the internet</text><path d=\"M195.0 283.0 L195.0 326.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"185.0\" y=\"305.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">out: 0.15</text><path d=\"M275.0 326.0 L275.0 283.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-phosphor)\"></path><text x=\"285.0\" y=\"305.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">in: free</text><text x=\"360.0\" y=\"408.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">dollars per gigabyte, price list of 16 September 2026</text></svg>", "caption": "The arrows carry the price, not the boxes. Leaving São Paulo is the dear direction."}
```

## What this changes in a design

Three rules fall out of the table, and the network lessons use all of them:

- **Spreading across zones is worth paying for, and it is not free.** Lesson 16 places subnets in
  every zone; lesson 22 puts a load balancer in front of them. Each design choice that sends traffic
  across a zone boundary on every request is a line on the bill, and the small number per gigabyte
  is multiplied by every request.
- **Keep chatty pairs in one zone when the failure does not matter**, such as a build machine and
  its cache, and across zones when it does, such as a database and its standby.
- **Where a copy lives is a price.** A second region for disaster recovery costs the transfer to
  reach it every day, not only the machines that wait there. Lesson 14 reads a whole bill, and the
  transfer lines are where it starts.

The program left the files it downloaded in `~/.cache/aws-prices`, so asking again costs nothing.
Lessons 14, 17 and 20 run it against other offers.
