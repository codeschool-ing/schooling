---
title: How Lighthouse reaches a score
version: 1
---

**The performance score is five metrics, each turned into a score of its own and then averaged with
a weight.** The weights are in every report, and `tools/report.ts` printed them:

| metric | weight | what it is |
|---|---|---|
| **TBT**, Total Blocking Time | 30 | how long the main thread was blocked by long tasks during the load |
| **LCP**, Largest Contentful Paint | 25 | lesson 5's, measured during this one load |
| **CLS**, Cumulative Layout Shift | 25 | lesson 5's, during the load only |
| **FCP**, First Contentful Paint | 10 | the first moment anything was painted |
| **SI**, Speed Index | 10 | how quickly the window filled in, read off a film of the load |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"The performance score drawn as one bar of a hundred, split by weight: TBT 30, LCP 25, CLS 25, FCP 10 and SI 10. The first three, which stand for the Core Web Vitals, make seventy of the hundred.\"><rect x=\"40\" y=\"40\" width=\"192.0\" height=\"40\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"136.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TBT 30</text><rect x=\"232.0\" y=\"40\" width=\"160.0\" height=\"40\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">LCP 25</text><rect x=\"392.0\" y=\"40\" width=\"160.0\" height=\"40\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CLS 25</text><rect x=\"552.0\" y=\"40\" width=\"64.0\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"584.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">FCP 10</text><rect x=\"616.0\" y=\"40\" width=\"64.0\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SI 10</text><line x1=\"40\" y1=\"96\" x2=\"488.0\" y2=\"96\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"264.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">70: the Core Web Vitals, or the lab's stand-in</text></svg>", "caption": "Seventy points of the hundred come from the three things a person feels."}
```

Each value becomes a score between 0 and 100 on a curve Lighthouse fits to how real sites measure,
so that a value most sites beat scores low and one few sites reach scores high. Then the five are
averaged with the weights. **Seventy percent of the score is TBT, LCP and CLS**, and that is no
accident: they are the three Core Web Vitals, or the nearest a lab can get to them.

## Why TBT and not INP

**INP needs somebody to interact, and Lighthouse only loads the page.** Nobody clicks. What it can
measure is what would make a click wait: **long tasks**, pieces of work on the main thread of 50
milliseconds or more. TBT adds up, for every long task between the first paint and the moment the
page settles, the part of it beyond 50 milliseconds. A task of 120 milliseconds adds 70; a task of 40
adds nothing. A page with a high TBT is a page where a tap during the load would have waited, which
is why TBT carries the largest weight. Lighthouse can measure INP itself in its *timespan* mode, which
records a person or a script using the page, but the score this lesson reads is a load.

## The phone it pretends to be

The report also says what it measured on, under `configSettings`. For the default run, which is a
mobile one, it is:

- a window 412 pixels wide and 823 high, with the user agent of a mid-range Android phone;
- a network with 150 milliseconds of round trip and 1.6 megabits a second;
- a processor four times slower than the computer running it.

**That is a slow phone on a slow 4G connection, on purpose.** A site that is fine there is fine
almost anywhere, and many real visitors are on exactly that kind of device. `--preset=desktop`
measures as a desktop instead, with a faster network and no slowdown, and gives higher scores for the
same page.

## What the score is not

**A Lighthouse score is not a Core Web Vitals assessment.** The assessment of lesson 5 is field data
at the 75th percentile, from real visits; a Lighthouse score is one load, on one machine, under one set
of conditions. A page can score 100 here and fail in the field, because its real visitors click
things Lighthouse never clicks, or score 60 here and pass, because its real visitors are on fast
desktops. What the score is good for is comparing one version of a page with the next, measured the
same way, and its insights are good for knowing where to start.
