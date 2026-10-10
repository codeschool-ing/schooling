---
title: The quiet hours
version: 1
---

**At three in the morning a stream costs what it costs at noon.** The brokers keep their memory,
the consumers keep polling, the disks keep the week. That was the warning of lesson 1, and it can be
measured on your own cluster: leave it with nothing to do and ask what it holds.

## A broker with nothing to do

Nothing has been written for a while. The node's resident memory, how long it has been running and
how much processor time it has used in total:

```
ubuntu@stream:~/work$ ps -o rss,etime,time -p $(pgrep -f '^[^ ]*java .*node1')
```

A minute later, with still nothing written, and the disk the whole cluster holds after this lesson's
five topics:

```
ubuntu@stream:~/work$ ps -o rss,etime,time -p $(pgrep -f '^[^ ]*java .*node1')
```

`RSS` is in kilobytes. **The memory does not go back when the traffic stops**: the Java heap that
`cluster.sh` gave the node is reserved for as long as it runs, and the page cache of the data it
holds stays warm. The processor time barely moves, which is the good news: an idle broker is
cheap to run but not free to keep, because a machine rented by the hour is billed for the hour
whatever its processor does.

## When the batch is cheaper

Put lesson 1's question and this lesson's arithmetic side by side. A stream is worth what it costs
when somebody acts on the answer before the batch would have produced it. **What it costs is mostly
the hours with nothing in them.** For Ponto Final, open twelve hours a day, half of every day is quiet
hours, and the sales data itself fits in megabytes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A day from midnight to midnight. The shops sell from nine to twenty-one, drawn as a band of traffic. A stream's cost is a flat line across all twenty-four hours, the same at three in the morning as at noon. A nightly batch's cost is a single short block at two in the morning.\" data-fig=\"l17-day\"><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sales</text><line x1=\"130\" y1=\"75\" x2=\"690\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"0.8\"></line><text x=\"20\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">stream</text><line x1=\"130\" y1=\"140\" x2=\"690\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"0.8\"></line><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nightly batch</text><line x1=\"130\" y1=\"195\" x2=\"690\" y2=\"195\" stroke=\"var(--wire)\" stroke-width=\"0.8\"></line><text x=\"130.0\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><line x1=\"130.0\" y1=\"32\" x2=\"130.0\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"340.0\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"340.0\" y1=\"32\" x2=\"340.0\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"620.0\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><line x1=\"620.0\" y1=\"32\" x2=\"620.0\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"690.0\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><line x1=\"690.0\" y1=\"32\" x2=\"690.0\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><path d=\"M 340.0 75 C 363.33333333333337 50 386.6666666666667 45 421.6666666666667 48 C 456.6666666666667 52 503.3333333333333 46 550.0 50 C 596.6666666666667 55 608.3333333333333 70 620.0 75 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--phosphor-dim)\"></path><rect x=\"130.0\" y=\"113\" width=\"560.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">quiet hours</text><text x=\"480.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">paid every hour</text><rect x=\"176.66666666666666\" y=\"168\" width=\"9.333333333333343\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190.66666666666666\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">02:00</text></svg>", "caption": "The sales happen in twelve hours; the stream is paid for in twenty-four."}
```

So the answer is rarely all one or the other:

- **Stream what is acted on**, the stock on the website, a card to block, a promise that depends on
  now, and keep that part small: a few topics, a few consumers.
- **Batch what is read later**: reports, model training, the warehouse. They can read the same log
  once a night, as lesson 1 described, and pay for twenty minutes.
- **Scale with the day where the platform allows it.** Consumers are ordinary programs; running fewer
  of them at night, or none of a reporting consumer until morning, is cheap to arrange, and the lag
  they come back to is exactly the backlog lesson 16 taught you to read.
- **Look at the bill monthly against the arithmetic.** A stream that costs more than its messages
  times their bytes times their days says that something else is growing: partitions nobody uses,
  consumer groups nobody reads, retention nobody chose.

A stream that never sleeps is a decision, and like every other in this course it has a reason
written beside it, or it is a default nobody has looked at.
