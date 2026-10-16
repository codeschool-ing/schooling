---
title: Buffering, and how many objects a day it makes
version: 1
---

**A buffer is written when it is full or when it is old, whichever happens first.** `SizeInMBs` is
the first condition and `IntervalInSeconds` the second, and together they decide two things a team
notices only later: how long a record waits before it can be read in S3, and how many objects the
bucket collects in a day. AWS documents the ranges: the size from 1 to 128 MB, 5 by default, and the
interval up to 900 seconds, 300 by default. Either one bigger means fewer, larger objects that
arrive later.

moto does not enforce the ranges, which is worth seeing once, because a configuration that works in
the lab can be refused by AWS. The file of the last section, edited with `jq` to ask for 500 MB and
5,000 seconds:

```
ana@laptop:~/aws$ jq '.BufferingHints = {"SizeInMBs": 500, "IntervalInSeconds": 5000} | .Prefix = "raw/orders-big/"' orders-to-s3.json > orders-big.json
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-big --extended-s3-destination-configuration file://orders-big.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-big"
}
ana@laptop:~/aws$ aws firehose describe-delivery-stream --delivery-stream-name orders-big --query 'DeliveryStreamDescription.Destinations[0].ExtendedS3DestinationDescription.BufferingHints'
{
    "SizeInMBs": 500,
    "IntervalInSeconds": 5000
}
```

**moto stored both numbers and answered `ACTIVE`.** AWS validates the hints when the stream is
created and refuses values outside those ranges, so this request would have failed there; that
refusal was not run here. And moto does not buffer at all, as the last section showed, so nothing in
this lesson measures a buffer. What follows is the arithmetic AWS's documentation gives, done by
hand.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Fifteen minutes of two delivery streams with the same hints, 64 MB and 300 seconds. The busy stream, 0.23 MB a second, fills a 64 MB buffer in about 278 seconds, so the size writes it: three full objects in the fifteen minutes. The quiet stream, 0.012 MB a second, reaches only about 3.5 MB in 300 seconds, so the interval writes it: three objects at 300, 600 and 900 seconds, each nearly empty.\" data-fig=\"l21-buffers\"><text x=\"20.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">busy stream</text><text x=\"20.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.23 MB a second</text><rect x=\"151.0\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"151.0\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"315.8\" y1=\"34.0\" x2=\"315.8\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"317.8\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"317.8\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"482.6\" y1=\"34.0\" x2=\"482.6\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"484.6\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"484.6\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"649.4\" y1=\"34.0\" x2=\"649.4\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><text x=\"233.4\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">64 MB: size reached</text><text x=\"670.2\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">filling</text><text x=\"20.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quiet stream</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.012 MB a second</text><rect x=\"151.0\" y=\"130.0\" width=\"178.0\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"151.0\" y=\"186.7\" width=\"178.0\" height=\"3.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"329.0\" y1=\"124.0\" x2=\"329.0\" y2=\"194.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"331.0\" y=\"130.0\" width=\"178.0\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"331.0\" y=\"186.7\" width=\"178.0\" height=\"3.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"509.0\" y1=\"124.0\" x2=\"509.0\" y2=\"194.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"511.0\" y=\"130.0\" width=\"178.0\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"511.0\" y=\"186.7\" width=\"178.0\" height=\"3.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"689.0\" y1=\"124.0\" x2=\"689.0\" y2=\"194.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><text x=\"240.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3.5 MB: interval reached</text><line x1=\"150.0\" y1=\"205.0\" x2=\"690.0\" y2=\"205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"150.0\" y1=\"201.0\" x2=\"150.0\" y2=\"209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"150.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><line x1=\"330.0\" y1=\"201.0\" x2=\"330.0\" y2=\"209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"330.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300 s</text><line x1=\"510.0\" y1=\"201.0\" x2=\"510.0\" y2=\"209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"510.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600 s</text><line x1=\"690.0\" y1=\"201.0\" x2=\"690.0\" y2=\"209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"690.0\" y=\"222.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">900 s</text><text x=\"20.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "A buffer is written at 64 MB or at 300 seconds, whichever comes first; a quiet stream is written by the clock, nearly empty."}
```

## The arithmetic of one stream

**A busy stream fills its buffer before the interval ends.** Quitanda's order events of lesson 20
are 20 GB a day, about 0.23 MB a second on average. With the hints of `orders-to-s3.json`, 64 MB and
300 seconds, a buffer fills in 64 / 0.23 ≈ 278 seconds, just inside the interval. So the size is what writes it: about 20,000 MB / 64 MB ≈ 313 objects a day of 64 MB each. At the dinner peak, five times
the average, a buffer fills in under a minute; the objects stay the same size and simply come more
often.

**A quiet stream is written by the clock.** Quitanda's delivery drivers' app sends a location ping
stream of 1 GB a day, about 0.012 MB a second. With the same hints, 300 seconds pass long before
64 MB arrive, so the interval writes every buffer: 86,400 / 300 = 288 objects a day, of about 3.5 MB
each. Raising the interval to 900 seconds makes it 96 objects of about 10.4 MB, at the price of a
ping reaching S3 up to fifteen minutes after it was sent.

**The object count is a cost you pay later, on every read.** Lesson 19 is about why a lake of many
small files is slow and dear to query: every file is at least one `GET` request and, for Parquet, one
footer to read before any data, so an engine reading ten thousand small files spends its time
opening them. A delivery stream left at its defaults on a
quiet source is one of the commonest ways a lake fills with small files. The lever is the interval,
up to the delay the readers can bear, and after that a compaction job that rewrites a day's small
objects into a few large ones, the kind of Spark job lessons 17 and 24 run.

## One buffer per what

A delivery stream has one buffer per destination, and **with dynamic partitioning, one buffer per
partition**, which the next section sets up. Partitioned by Quitanda's three stores, the busy
stream above has three buffers filling at a third of the rate each, and each one is written by size or
by interval on its own. AWS sets the minimum size to 64 MB when dynamic partitioning is on. And the arithmetic multiplies: three stores and a dated prefix make three objects at a time where there was
one, and a key with a few hundred values makes a few hundred small buffers that the interval writes
half empty.
