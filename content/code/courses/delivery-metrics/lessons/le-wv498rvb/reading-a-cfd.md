---
title: Reading the shapes
version: 1
---

Nobody reads a CFD by measuring it every morning. They read its **shape**, and a handful of shapes recur on every team's chart. Each one points at a specific problem, and each one is visible days or weeks before the cycle times of finished items change.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 220\" role=\"img\" data-fig=\"l03-patterns\" aria-label=\"Three small cumulative flow diagrams drawn as sketches. In the first, the band between two lines widens because the upper line rises faster than the lower one: a bottleneck. In the second, the lower line goes flat while the upper one keeps rising: nothing is finishing. In the third, the lower line rises in steps: work crosses that boundary in batches.\"><rect x=\"20.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a band that widens</text><text x=\"120.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a queue is growing</text><path d=\"M34.0 136.0 L120.0 96.0 L206.0 56.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M34.0 146.0 L120.0 126.0 L206.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"246.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"346.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a line that goes flat</text><text x=\"346.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nothing is finishing</text><path d=\"M260.0 136.0 L346.0 96.0 L432.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M260.0 146.0 L346.0 110.0 L363.2 104.0 L432.0 104.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"472.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"572.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">stairs instead of a slope</text><text x=\"572.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">work moves in batches</text><path d=\"M486.0 136.0 L572.0 96.0 L658.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M486.0 148.0 L524.7 148.0 L524.7 124.0 L580.6 124.0 L580.6 98.0 L636.5 98.0 L636.5 74.0 L658.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path></svg>", "caption": "Three shapes worth knowing on sight. Each is visible days before the cycle times of finished items change."}
```

## A band that widens

When one band grows thicker while the others stay even, **work is entering that state faster than it leaves**. That state is the bottleneck, or the queue in front of it.

The Billing team's chart has exactly this through July. Read it off the table: on 3 July, 31 items had reached review and 22 had merged, so **9** were waiting for or in review; on 24 July it was 57 − 43 = **14**. Bia's queue was growing week by week, and nothing on the scatterplot of finished items said so yet, because the items stuck in it had not finished.

## A line that goes flat

On a CFD the lowest line is the last column, so a flat bottom line means **nothing is finishing**, and a flat top line means nothing is arriving. A flat line in the middle means nothing is crossing that boundary. The Billing team's *started* line is flat from 31 July to 7 August, at 78: for a week after the new rules, nobody started anything. That is not a problem; it is the limit doing its job, as each developer finished the three items they already had before taking a fourth. Read a flat line as a question, not a verdict.

## Stairs instead of a slope

A line that rises in steps means **work crosses that boundary in batches**. In June and July the *deployed* line lags the *merged* line and catches up once a week, because the pipeline ran on Thursdays. From August the two lines lie on top of each other. On a chart drawn daily the steps are unmistakable; in the Friday table they show as the gap between *merged* and *deployed*, which was 3 items on 24 July and none after the first week of August.

## A top band that keeps growing

The band between *arrived* and *started* is the backlog. On the Billing team's chart it grew from 20 items on 5 June to 21 on 31 July, and it was 17 on 25 September: nearly level, with requests arriving about as fast as the team started them. **A backlog band that only grows is a promise the team is not keeping**, and it is the shape behind lesson 2's finding that the requester's wait was mostly backlog.

## What the shapes do not tell you

A CFD describes the board as a whole. It cannot tell you **which** item is stuck, only that items are piling up somewhere; and an item that sits still while others flow past it barely changes any band. One blocked item among a hundred is a line one item thick. The chart for that is the subject of the next section.
