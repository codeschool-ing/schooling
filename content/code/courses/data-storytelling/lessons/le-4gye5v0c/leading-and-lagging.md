---
title: The right number, and when it arrives
version: 1
---

The most important design decision on a dashboard is not where things go but **which numbers are on it at
all**. A beautiful layout of the wrong measures is worse than a plain one of the right ones, because it
looks finished.

## A number that would change a decision

The test for a tile is the one lesson 1 applied to slides, with a time limit: **if this number moved
sharply this week, would somebody do something different?** Orders today would change nothing Paulo does;
it is there because it is easy to get. The first-delivery on-time rate would change something at once:
a drop means the warehouse check is backing up again.

## Leading and lagging

Faro's real target is fewer early cancellations. The trouble is that a cancellation within ninety days is
only known ninety days later. **A dashboard that shows only the cancellation rate shows today what happened
to customers who joined three months ago**, and any change made now will not appear on it for another
quarter.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 200\" role=\"img\" data-fig=\"l07-leading\" aria-label=\"A timeline in weeks from 0 to 14. At week 0 a new subscriber’s first box arrives on time or late, and the first-delivery rate shows it the same week: the leading indicator. At about week 13, ninety days later, the cancellation within 90 days is finally known: the lagging indicator. A bracket between them is labelled ninety days in which only the leading one can warn you.\"><path d=\"M40.0 120.0 L640.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40.0 120.0 L40.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"40.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M125.7 120.0 L125.7 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"125.7\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><path d=\"M211.4 120.0 L211.4 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"211.4\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><path d=\"M297.1 120.0 L297.1 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"297.1\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><path d=\"M382.9 120.0 L382.9 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"382.9\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><path d=\"M468.6 120.0 L468.6 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"468.6\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M554.3 120.0 L554.3 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"554.3\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12</text><path d=\"M640.0 120.0 L640.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"640.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><text x=\"640.0\" y=\"156.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">weeks after the first box</text><circle cx=\"40.0\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M40.0 114.0 L40.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"40.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">first box: on time or late</text><text x=\"40.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">leading: seen this week</text><circle cx=\"591.0\" cy=\"120.0\" r=\"6\" fill=\"var(--amber)\"></circle><path d=\"M591.0 114.0 L591.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"591.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">cancelled within 90 days?</text><text x=\"591.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lagging: known now</text><path d=\"M50.0 100 L50.0 106 L581.0 106 L581.0 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"315.5\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ninety days in which only the leading indicator can warn you</text><text x=\"40.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a change made today appears in the cancellation rate a quarter later</text></svg>", "caption": "The outcome Faro cares about arrives ninety days late. The first-delivery rate moves the same week, which is why it gets the top-left corner."}
```

So measures come in pairs:

- a **lagging** indicator is the outcome you care about, measured after the fact: the ninety-day
  cancellation rate;
- a **leading** indicator is something you can see now that moves before the outcome does: the share of
  first boxes delivered on time this week.

The leading indicator is only worth watching if it really does lead, and that is what Marina's analysis
established: late first boxes go with more than double the cancellations. **That is why the
first-delivery rate earns the top-left corner**: it is the earliest warning the data can give, weeks before
the cancellations it predicts.

## Keep both

A dashboard of leading indicators alone can drift away from the goal: the first-delivery rate could reach
95% and cancellations stay high for some other reason. So the lagging measure stays on the dashboard,
beside the leading one, as the check that the two still move together. **When they stop moving together,
that is itself a finding**, and the start of the next analysis.
