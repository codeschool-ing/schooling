---
title: Serving files to the internet
version: 1
---

**Bytes that leave Google Cloud for the internet are the most expensive thing a bucket does**, and
they are billed to the bucket's project whoever asked for them. A public website's images, a mobile
app's downloads, a report a customer fetches: each byte out is metered, at 0.12 a GiB for the first
10 TiB of the month to destinations outside Asia and Australia, which is where Brazil falls. That is
almost three and a half times the price of keeping the same byte for a month in Standard.

The table, from the "General network usage" part of cloud.google.com/storage/pricing, read
2026-10-30, per GiB:

| destination | first 10 TiB | 10 to 150 TiB | above 150 TiB |
|---|---|---|---|
| worldwide, excluding Asia and Australia | 0.12 | 0.11 | 0.08 |
| Asia, excluding China, including Hong Kong | 0.12 | 0.11 | 0.08 |
| Australia | 0.19 | 0.18 | 0.15 |

China, excluding Hong Kong, has steps of its own: 0.23 for the first TiB, 0.22 up to 10 TiB and 0.20
above.

**This table is not per region.** The page prints one, for every bucket, and the price follows where
the bytes go rather than where they came from. That is a difference from a virtual machine: the
network pricing page, cloud.google.com/vpc/network-pricing, prints a Premium Tier table for traffic
leaving `southamerica-east1`, and it starts at 0.19 a GiB for the first TiB to North America, Europe
or South America. The same byte costs less to send out of a bucket in São Paulo than out of a machine
beside it, and lesson 6 meets the machine's table again for Cloud SQL.

Quitanda's product images are 500 GiB, and the app and the site download about 20 TiB of them a
month. That is the third line of the program in the previous section:

```
500 GiB of images, 20 TiB out         17.50     21.47   2,355.20   2,394.17
```

**Storage is 17.50 of a month that costs 2,394.17.** The requests, 53.7 million downloads of
400 KiB, are 21.47 at the Class B rate. The other 2,355.20 is the transfer, priced through the tiers
by `tiers()`: the first 10,240 GiB at 0.12 is 1,228.80, and the remaining 10,240 GiB at 0.11 is
1,126.40. The tiers lower the price as the month's volume grows, and a project has to send 150 TiB in
a month before it reaches the cheapest, 0.08.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two staircases of price per GiB against the TiB sent in a month. Cloud Storage to the internet: 0.12 for the first 10 TiB, 0.11 up to 150 TiB, 0.08 above. Cloud CDN to viewers in South America: 0.09 for the first 10 TiB, 0.06 up to 150 TiB, 0.05 above. Quitanda, at 20 TiB a month, pays 2,355.20 USD from the bucket, or 1,536.00 USD of cache transfer through Cloud CDN.\" data-fig=\"l05-gcs-tiers\"><path d=\"M80.0 250.0 L680.0 250.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.04</text><path d=\"M80.0 210.0 L680.0 210.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.06</text><path d=\"M80.0 170.0 L680.0 170.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.08</text><path d=\"M80.0 130.0 L680.0 130.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.10</text><path d=\"M80.0 90.0 L680.0 90.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.12</text><path d=\"M80.0 50.0 L680.0 50.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.14</text><path d=\"M80.0 250.0 L680.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M110.0 250.0 L110.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M230.0 250.0 L230.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"230.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M530.0 250.0 L530.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"530.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M680.0 250.0 L680.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"680\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">TiB sent in a month</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">USD per GiB, in that tier</text><path d=\"M80.0 90.0 L110.0 90.0 L110.0 110.0 L530.0 110.0 L530.0 170.0 L680.0 170.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M80.0 150.0 L110.0 150.0 L110.0 210.0 L530.0 210.0 L530.0 230.0 L680.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"114\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.12</text><text x=\"330\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.11</text><text x=\"605\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.08</text><text x=\"114\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.09</text><text x=\"330\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.06</text><text x=\"605\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.05</text><path d=\"M140.0 116.0 L140.0 246.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"140.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"140.0\" cy=\"210.0\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"148\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">Quitanda, 20 TiB: 2,355.20 USD</text><text x=\"148\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">through Cloud CDN: 1,536.00 USD</text><path d=\"M420.0 40.0 L450.0 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"458\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud Storage to the internet</text><path d=\"M420.0 58.0 L450.0 58.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"458\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud CDN to viewers in South America</text></svg>", "caption": "Transfer to the internet is a staircase, not a rate: each step applies only to the GiB that fall on it. At 20 TiB, Quitanda pays the whole first step and part of the second, on either staircase."}
```

**The free allowance does not reach São Paulo.** Cloud Storage's Always Free tier includes 100 GB of
transfer a month, and the page limits all of it, the storage and the operations too, to buckets in
`us-west1`, `us-central1` and `us-east1`. A bucket in `southamerica-east1` starts paying with the
first byte.

## Behind Cloud CDN

**Cloud CDN is Google's cache at the edge of its network**, and Cloud Storage can be its origin. A
viewer's request reaches the nearest edge. If the edge has a copy, it answers, and the bucket never
hears of it; if it does not, it fetches the object from the bucket once, keeps it, and answers the
next thousand requests from the copy. **The bucket's own transfer charge is waived** for what it sends
to Cloud CDN, as the storage pricing page says under "Specialty network services", and Cloud CDN then
charges its own prices, from cloud.google.com/cdn/pricing, read 2026-10-30:

| what Cloud CDN charges | price |
|---|---|
| cache transfer out, to South America, first 10 TiB | 0.09 a GiB |
| the same, 10 to 150 TiB | 0.06 a GiB |
| cache fill, origin and edge both in South America | 0.02 a GiB |
| cache lookups, every `GET` and `HEAD` | 0.0075 per 10,000 |

The fourth line of the program assumes 19 downloads in 20 are answered from the cache:

```
the same behind Cloud CDN             17.50     41.34   1,556.48   1,615.32
```

**The requests went up and the transfer came down.** Every one of the 53.7 million downloads is a
cache lookup at 0.0075 per 10,000, 40.27, more than the bucket's own reads cost; the bucket still
answers the 2.7 million misses, 1.07. But the 20 TiB now leave through Cloud CDN at its lower
staircase, 1,536.00, plus the 1 TiB of misses the cache fetched from the bucket at 0.02, 20.48. The
month falls from 2,394.17 to 1,615.32.

**That total leaves one thing out, and says so in its label.** Cloud CDN serves a bucket through an
external Application Load Balancer, which `gcp-foundations` lesson 20 builds, and the load balancer
has charges of its own on the network pricing page: an hourly price for its forwarding rules and a
price per GiB it processes. Which of them applies to traffic the cache answers is a question for that
page's footnotes, and nothing here checked it. So the 1,615.32 is a floor, and the comparison it
supports is the shape: past a few TiB a month, a cache in front of a public bucket is cheaper than
the bucket alone, and the hit ratio decides by how much.

It has a second effect that matters as much as the price: the bucket stops being the address the
internet talks to. With the load balancer and the cache in front, the bucket can keep the public
access prevention of lesson 4 and let only the cache read it.
