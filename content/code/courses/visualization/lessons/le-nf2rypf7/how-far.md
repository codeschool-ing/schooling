---
title: How far to go
version: 1
---

Taken literally, maximising the data-ink ratio ends with a chart nobody can read:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 210\" role=\"img\" data-fig=\"l17-too-far\" aria-label=\"Two versions of the category chart. On the left, everything but the bars has been removed: no names, no values, no axis, so the reader sees six bars and cannot say what any of them is. On the right, the bars keep their names and values, and nothing else.\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">too far: only the bars</text><path d=\"M30.0 44.5 h201.4 v17.0 h-201.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M30.0 70.5 h188.7 v17.0 h-188.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M30.0 96.5 h171.6 v17.0 h-171.6 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M30.0 122.5 h145.7 v17.0 h-145.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M30.0 148.5 h134.0 v17.0 h-134.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M30.0 174.5 h116.8 v17.0 h-116.8 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"320.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">enough: names and values</text><path d=\"M400.0 44.5 h164.8 v17.0 h-164.8 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"394.0\" y=\"53.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Vegetables</text><text x=\"568.8\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">412</text><path d=\"M400.0 70.5 h154.4 v17.0 h-154.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"394.0\" y=\"79.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Fruit</text><text x=\"558.4\" y=\"79.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">386</text><path d=\"M400.0 96.5 h140.4 v17.0 h-140.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"394.0\" y=\"105.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Dairy</text><text x=\"544.4\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">351</text><path d=\"M400.0 122.5 h119.2 v17.0 h-119.2 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"394.0\" y=\"131.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Bakery</text><text x=\"523.2\" y=\"131.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">298</text><path d=\"M400.0 148.5 h109.6 v17.0 h-109.6 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"394.0\" y=\"157.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Drinks</text><text x=\"513.6\" y=\"157.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">274</text><path d=\"M400.0 174.5 h95.6 v17.0 h-95.6 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"394.0\" y=\"183.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Pantry</text><text x=\"499.6\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">239</text></svg>", "caption": "The aim is not the least ink possible. Names, units and values are not data in Tufte's sense, but a chart without them cannot be read."}
```

Category names, units and a title are non-data ink in Tufte's strict sense, and every one of them is
essential. So the principle needs a limit, and the limit is the reader: **remove what they would not
miss, keep what they would**.

## What research says about decoration

Tufte's advice was argued from taste and experience, and it has been tested since. Bateman and
colleagues, in a 2010 study called *Useful Junk?*, compared plain charts with heavily illustrated
versions of the same data. Readers interpreted both equally accurately, and two to three weeks later
they remembered the illustrated ones better.

That does not overturn the principle, but it sharpens it:

- **Decoration that distorts** is always wrong: 3D, gradients that change apparent length, pictures
  that hide the data.
- **Decoration that does not distort** has a cost in attention and may have a benefit in memory. On a
  poster meant to be remembered, an illustration can earn its place. On a dashboard read every
  morning, it is noise the reader pays for every day.
- **Defaults are never a reason.** Whatever stays on the chart should stay because somebody decided
  it helps.

## A working rule

For analysis and for dashboards, start from the clean version and add back only what a reader asked
for. For a single chart meant to persuade or to be remembered, a little well-chosen decoration is
defensible, as long as the data is drawn honestly underneath it.
