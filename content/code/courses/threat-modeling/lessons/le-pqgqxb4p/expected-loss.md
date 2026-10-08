---
title: Expected loss
version: 1
---

Multiplying the two halves gives one number per risk: **the loss you should expect per year**,
averaged over many years.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l09-ale\" aria-label=\"Expected loss per year for T01, the forged webhook. Likelihood: 0.5 events a year, one every two years on average. Impact: R$ 12,000 per event. Multiplied: R$ 6,000 a year.\"><rect x=\"20.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">likelihood</text><text x=\"120.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">0.5 a year</text><text x=\"120.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one event every two years</text><rect x=\"260.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">impact</text><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">R$ 12,000</text><text x=\"360.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">per event</text><rect x=\"500.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">expected loss</text><text x=\"600.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">R$ 6,000</text><text x=\"600.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">per year</text><text x=\"230.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">×</text><text x=\"470.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">=</text><text x=\"360.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">SLE × ARO = ALE, in the classic names</text></svg>", "caption": "An average over many years, not a forecast for next year: most years T01 costs nothing, and some years it costs twelve thousand."}
```

> expected loss per year = events per year × cost per event

The classic security literature calls the same three quantities the **single loss expectancy**
(SLE, the cost of one event), the **annual rate of occurrence** (ARO, events per year) and the
**annualised loss expectancy** (ALE = SLE × ARO). The names are worth recognising because auditors
and insurers use them; the arithmetic is the same.

For T03, a staff account phished to every record:

> 0.3 a year × R$ 250,000 per event = R$ 75,000 a year

That does not mean Vereda loses R$ 75,000 every year. Most years it loses nothing to T03; about one
year in four, it loses a quarter of a million. **The expected value is what the average
year costs over a long run**, which is the right number for a budget and the wrong number for
imagining any particular year. The last section of this lesson is about that difference.

### What it is good for

Expected loss turns a list of threats into something that adds up. Nine risks at Vereda come to
**R$ 139,400 a year**, and one of them is more than half the total. Neither fact was visible in a
list of high, medium and low, and both change what gets done first.

It also gives a ceiling for spending. If a control removes most of T03's R$ 75,000 a year, it is
worth paying for if it costs much less than that. Lesson 11 makes that comparison properly,
because "much less" depends on how sure the estimate is.

### What it is not

**It is not a prediction.** An expected loss of R$ 9,000 a year from T14 does not mean that R$
9,000 will be lost next year; it almost certainly will not be.

**It is not precise.** It is the product of two estimates, each of which may be wrong by a factor
of two or more. Writing R$ 75,000 rather than "about seventy-five thousand" is a convenience for
arithmetic, not a claim to accuracy. Two estimates that differ by 10% are a tie.

**It is not the whole risk.** It says nothing about how bad a bad year can get, which for some
risks is the only question that matters.
