---
title: Paying per request
version: 1
---

A function platform bills for what your code used, usually in two parts: **a price per request**, and
**a price per unit of compute time**, measured as memory multiplied by duration, in gigabyte-seconds.
A function given 512 MB that runs for 200 ms uses 0.5 × 0.2 = 0.1 GB-s.

As this lesson was written, AWS published these prices for Lambda on x86 in its `us-east-1` region,
with a monthly free allowance of one million requests and 400,000 GB-s per account:

| item | price |
| --- | --- |
| requests | US$ 0.20 per million |
| compute | US$ 0.0000166667 per GB-s |

**Prices change, and differ by region and by provider**; check the provider's own page before using
these for anything real. The arithmetic below does not depend on the exact figures.

## A worked month

Quitanda's delivery quotes: 3 million requests a month, each running 200 ms with 512 MB, ignoring the
free allowance.

| | calculation | per month |
| --- | --- | --- |
| compute | 3,000,000 × 0.1 GB-s = 300,000 GB-s, × 0.0000166667 | US$ 5.00 |
| requests | 3 million × US$ 0.20 | US$ 0.60 |
| total | | US$ 5.60 |

## Where an always-on server wins

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A chart of monthly cost against requests per month. The pay-per-request line starts at zero and rises in a straight line. The always-on server is a flat line. The two cross at a break-even volume; below it paying per request is cheaper, above it the server is.\"><defs><marker id=\"l3-cost-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M70 230 L690 230\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-cost-ah-wire)\"></path><path d=\"M70 230 L70 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-cost-ah-wire)\"></path><text x=\"380\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">requests per month</text><text x=\"76\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cost per month</text><path d=\"M70 230 L660 50\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70 140 L660 140\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"540\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">pay per request</text><text x=\"640\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">always-on server</text><circle cx=\"365\" cy=\"140\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></circle><path d=\"M365 146 L365 228\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"365\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">break-even</text><text x=\"200\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">functions cheaper</text><text x=\"520\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">server cheaper</text></svg>", "caption": "Paying per request is a straight line from zero; a server is a flat line. Where they cross is the break-even volume the next paragraphs compute."}
```

Paying per request is a straight line that starts at zero: twice the requests, twice the bill. A
server you rent by the month is a flat line: the same price at one request or at a hundred a second,
up to what it can handle. **The two lines cross**, and the crossing is easy to compute.

One request costs the request price plus its compute: US$ 0.20 / 1,000,000 + 0.1 × US$ 0.0000166667
= about US$ 0.00000187. Suppose a server that could carry the same load costs US$ 30 a month; that
figure is an assumption for the example, not a quote. The break-even is US$ 30 divided by the cost
of one request: about **16 million requests a month**, which is a little over six requests a second
on average.

Below that volume the function is cheaper, and far cheaper when the traffic comes in bursts. Above it,
and especially for traffic that is steady all day, the server is. **Steady load is what an always-on
server is good at, and bursty or rare load is what functions are good at**; the bill only says the
same thing in money.

## What the bill leaves out

The comparison above counts machines and not people. A function needs no operating system patched,
no capacity planned and no process restarted at three in the morning, and that work has a cost too.
On the other side, each copy of a function holds its own database connection, and a platform that
starts a thousand copies in a burst opens a thousand connections at once, which can exhaust the
database. **Functions move the operational cost; they do not delete it.**
