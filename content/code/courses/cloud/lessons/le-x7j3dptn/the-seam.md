---
title: "The seam: what the link costs"
version: 1
---

The link between two environments costs time and money, and the money is **not the same in both
directions**. Here is the part of the course's price sheet that covers it: the AWS public price
list for `sa-east-1` (São Paulo) and `us-east-1` (N. Virginia), in USD, excluding tax, at the offer
versions it prints.

```
ana@laptop:~/cloud$ python3 prices.py transfer
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

Data transfer, USD per GB
  out to the internet, first 10 TB         0.1500       0.0900
  out to the internet, next 40 TB          0.1380       0.0850
  out to the internet, next 100 TB         0.1260       0.0700
  out to the internet, over 150 TB         0.1140       0.0500
  between zones, each direction            0.0100       0.0100
  to the other region                      0.1380       0.0200
  in from the internet                     0.0000       0.0000
```

The last line is the one to notice first. **Data coming in from the internet costs nothing**, in
either region. Data going out to the internet is charged per gigabyte, at a price that falls as the
month's volume grows. Moving data between two zones of one region costs 0.0100 USD per GB in each
direction, and sending it from São Paulo to another region costs 0.1380 per GB. The list does not
say why the directions differ. The effect is plain enough: bringing data in is free, and taking it
away is billed.

## How a tier is counted

"First 10 TB, next 40 TB" can be read two ways. Either the whole month is priced at the rate of the
tier it ends in, or each tier prices only the gigabytes that fall inside it. The offer file itself
settles it, and it is public: this fetches the data-transfer offer for `sa-east-1`, at the version
the sheet printed, and lists the ranges of the out-to-the-internet line.

```
ana@laptop:~/cloud$ curl -s -o dt.json https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSDataTransfer/20260916132208/sa-east-1/index.json
ana@laptop:~/cloud$ jq -r '(.products[] | select(.attributes.usagetype == "SAE1-DataTransfer-Out-Bytes") | .sku) as $s | [.terms.OnDemand[$s][].priceDimensions[]] | sort_by(.beginRange | tonumber)[] | [.beginRange, .endRange, .description] | join("  ")' dt.json
0  10240  $0.150 per GB - up to 10 TB / month data transfer out
10240  51200  $0.138 per GB - next 40 TB / month data transfer out
51200  153600  $0.126 per GB - next 100 TB / month data transfer out
153600  Inf  $0.114 per GB - greater than 150 TB / month data transfer out
```

The ranges are in GB, and the first ends at `10240`, so **a TB on this list is 1,024 GB**. Each
range carries its own price, which is the second reading: a gigabyte is priced by the range it falls
in, and crossing 10 TB does not re-price the first 10.

## Fifty terabytes out of São Paulo

A company moves 50 TB out of `sa-east-1` to its own datacentre over a VPN, which travels over the
internet, in one month. Step by step:

1. 50 TB is 50 × 1,024 = 51,200 GB.
2. The first 10,240 GB are priced at 0.150: 10,240 × 0.150 = 1,536.00 USD.
3. What is left, 51,200 − 10,240 = 40,960 GB, falls in the next-40-TB tier, which ends at exactly
   51,200. At 0.138: 40,960 × 0.138 = 5,652.48 USD.
4. The total is 1,536.00 + 5,652.48 = **7,188.48 USD**.

The two tempting shortcuts are both wrong. Pricing all 51,200 GB at the first tier's 0.150 gives
7,680.00; pricing all of it at 0.138, the tier the month ends in, gives 7,065.60.

The same arithmetic, as a program that walks the tiers:

```schooling-example
{
  "language": "python",
  "file": "egress.py",
  "parts": [
    {
      "code": "import sys\n\n# sa-east-1, out to the internet, USD per GB, from `prices.py transfer`\nTIERS = [\n    (10 * 1024, 0.150),    # first 10 TB\n    (40 * 1024, 0.138),    # next 40 TB\n    (100 * 1024, 0.126),   # next 100 TB\n    (None, 0.114),         # over 150 TB\n]",
      "note": "The four `out to the internet` lines of the sheet for `sa-east-1`, each with the size of its tier in GB. The last tier has no end, so its size is `None`."
    },
    {
      "code": "tb = float(sys.argv[1])\nleft = tb * 1024           # the tiers are written in GB, 1,024 to a TB\ntotal = 0.0",
      "note": "The month's volume in TB from the command line, turned into GB the way the price list counts them: `10240` is where the first tier ends, so a TB here is 1,024 GB."
    },
    {
      "code": "for size, price in TIERS:\n    gb = left if size is None else min(left, size)\n    if gb <= 0:\n        break",
      "note": "Walk the tiers in order, first to last. Each one takes at most its own size out of what is left, and the walk stops when nothing is left."
    },
    {
      "code": "    cost = gb * price\n    print(f'{gb:>9,.0f} GB x {price:.3f} = {cost:>10,.2f}')\n    total += cost\n    left -= gb",
      "note": "**The price applies only to the gigabytes inside its tier.** Print the tier's line, add it to the total and take those gigabytes off what is left."
    },
    {
      "code": "print(f'{\"total\":>20} = {total:>10,.2f} USD')",
      "note": "The sum of the tiers, lined up under them."
    }
  ]
}
```

```
ana@laptop:~/cloud$ python3 egress.py 50
   10,240 GB x 0.150 =   1,536.00
   40,960 GB x 0.138 =   5,652.48
               total =   7,188.48 USD
ana@laptop:~/cloud$ python3 egress.py 200
   10,240 GB x 0.150 =   1,536.00
   40,960 GB x 0.138 =   5,652.48
  102,400 GB x 0.126 =  12,902.40
   51,200 GB x 0.114 =   5,836.80
               total =  25,927.68 USD
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A step chart of the price of data transfer out to the internet from sa-east-1, in USD per GB, against the terabytes sent in one month, from 0 to 200. The price is 0.150 for the first 10 TB, 0.138 up to 50 TB, 0.126 up to 150 TB and 0.114 beyond. The area under the steps up to 50 TB is shaded in two blocks: 10,240 GB at 0.150, which is 1,536.00 USD, and 40,960 GB at 0.138, which is 5,652.48 USD, together 7,188.48 USD. Traffic in from the internet is priced at zero and would be a line along the bottom axis.\"><defs><marker id=\"eg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"90\" y=\"62.5\" width=\"30\" height=\"187.5\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"77.49999999999997\" width=\"120\" height=\"172.50000000000003\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><path d=\"M90 40 L90 250 L700 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"82\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD per GB</text><text x=\"390.0\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">TB sent out to the internet in one month</text><path d=\"M90 250 L90 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M120 250 L120 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"120\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M240 250 L240 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"240\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M540 250 L540 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"540\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M690 250 L690 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"84\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M90 62.5 L120 62.5 L120 77.49999999999997 L240 77.49999999999997 L240 92.5 L540 92.5 L540 107.5 L690 107.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"84\" y=\"62.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.150</text><text x=\"180.0\" y=\"67.49999999999997\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.138</text><text x=\"390.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.126</text><text x=\"615.0\" y=\"97.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.114</text><text x=\"84\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,536.00</text><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5,652.48</text><path d=\"M240 37.49999999999997 L240 77.49999999999997\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"246\" y=\"37.49999999999997\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">50 TB out: 7,188.48 USD</text><text x=\"690\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in from the internet: 0.0000</text></svg>", "caption": "The bill is the area under the steps. Each tier prices only the gigabytes inside it, so crossing 10 TB does not re-price the first 10; the 50 TB of the worked example is the two shaded blocks."}
```

The same 50 TB out of `us-east-1` would be 10,240 × 0.090 + 40,960 × 0.085 = 921.60 + 3,481.60 =
4,403.20 USD. The shape of the list is the same; the region moves every price.

## Data gravity

Time is the other cost. 51,200 GB is about 409,600 gigabits, taking a GB as a billion bytes and
eight bits to the byte. A 1 Gbit/s link doing nothing else moves that in 409,600 seconds, which is
**almost five days**. A dataset that big is not moved on a whim, and it gets bigger every month it
stays where it is.

That is what people mean by **data gravity**. Once a large body of data lives somewhere, the
applications that use it are pulled towards it, because running compute next to the data costs
neither transfer time nor a bill per gigabyte, while moving the data costs both. The first big
dataset a company puts somewhere tends to decide where its next applications run.

For a hybrid design the rule of thumb follows: put the compute on the side where the data it reads
most already is, and send results across the seam rather than raw data. A report of a few megabytes
crossing once a night costs a fraction of a cent; the table it was built from crossing every hour
is the bill above, over and over. Round-trip time adds to each crossing too, and lesson 9 measures
it between regions.
