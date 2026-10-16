---
title: Serving files to the internet
version: 1
---

**Bytes that leave AWS for the internet are the most expensive thing S3 does**, and they are billed
to the bucket's owner whoever asked for them. A public website's images, a mobile app's downloads, a
report a customer fetches: each byte out is metered at 0.15000 a GB for the first 10 TB of the month
in São Paulo, almost four times the price of keeping that byte for a month.

Quitanda's product images are 500 GB, and the app and the site serve about 20 TB of them a month.
Those are the third line of the program in the previous section:

```
500 GB of images, 20 TB out         20.25     29.12   2,949.12   2,998.49
```

**Storage is 20.25 of a month that costs 2,998.49.** The requests, 52 million `GET`s, are 29.12. The
other 2,949.12 is the transfer, priced through the tiers by `egress()`: the first 10,240 GB at
0.15000 is 1,536.00, and the remaining 10,240 GB at the second tier's 0.13800 is 1,413.12. The tiers
lower the price per GB as the month's volume grows, and a company has to send 150 TB in a month
before it reaches the cheapest one, 0.11400.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The price per GB of transfer from S3 in São Paulo to the internet, in steps of monthly volume: 0.150 for the first 10 TB, 0.138 up to 50 TB, 0.126 up to 150 TB and 0.114 above that. Quitanda, at 20 TB a month, is on the second step: 2,949.12 USD, on average 0.144 a GB.\" data-fig=\"l05-tiers\"><path d=\"M80.0 250.0 L680.0 250.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.10</text><path d=\"M80.0 183.3 L680.0 183.3\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72.0\" y=\"183.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.12</text><path d=\"M80.0 116.7 L680.0 116.7\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72.0\" y=\"116.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.14</text><path d=\"M80.0 50.0 L680.0 50.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.16</text><path d=\"M80.0 250.0 L680.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M110.0 250.0 L110.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M230.0 250.0 L230.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"230.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M530.0 250.0 L530.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"530.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M680.0 250.0 L680.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"680.0\" y=\"288.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">TB sent to the internet in a month</text><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">USD per GB, in that tier</text><path d=\"M80.0 83.3 L110.0 83.3 L110.0 123.3 L230.0 123.3 L230.0 163.3 L530.0 163.3 L530.0 203.3 L680.0 203.3\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"114.0\" y=\"71.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.150</text><text x=\"170.0\" y=\"111.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.138</text><text x=\"380.0\" y=\"151.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.126</text><text x=\"605.0\" y=\"191.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.114</text><path d=\"M140.0 129.3 L140.0 246.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"140.0\" cy=\"123.3\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"148.0\" y=\"208.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">Quitanda, 20 TB: 2,949.12 USD</text><text x=\"148.0\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">on average 0.144 a GB</text></svg>", "caption": "Transfer to the internet is a staircase, not a rate: each step applies only to the GB that fall on it. Quitanda's 20 TB pay the whole first step and half of the second."}
```

AWS also gives every account a free allowance of transfer to the internet each month, which the price
sheet does not print; `cloud` lesson 10, "The lines nobody expects", prints it as 100 GB. Against
20 TB it is half of one per cent.

## Behind CloudFront

**Transfer from S3 to CloudFront is free**: the sheet's line `to CloudFront` is 0.00000. CloudFront,
from `aws-foundations` lesson 23, is AWS's network of edge locations. It fetches an object from the
bucket once, keeps a copy close to the viewers, and serves the next thousand requests for it from the
copy. The bucket sees one `GET` instead of a thousand and sends nothing to the internet itself.

The fourth line of the program assumes 95 of every 100 downloads are served from CloudFront's cache,
so the bucket answers 2.6 million `GET`s, which cost 1.46:

```
the same behind CloudFront          20.25      1.46          -          -
```

**The dashes are honest.** S3's own transfer to CloudFront is 0.00, and CloudFront then charges its
own price for delivering the bytes to viewers, per GB and per request. That price is in CloudFront's
offer, which this course's price sheet does not read, so the program prints no transfer and no total.
What the line does show is the half that belongs to S3: the 2,949.12 of the line above is gone from
the bucket's bill. Whether the whole is cheaper depends on CloudFront's price and on the share of
downloads its cache answers, and neither was checked here.

It has a second effect that matters as much: the bucket stops being the address the internet talks
to. With CloudFront in front, the bucket can stay private behind the Block Public Access of lesson 4,
with a bucket policy that lets only CloudFront read it.
