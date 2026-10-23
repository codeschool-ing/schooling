---
title: "CLS: whether the page holds still"
version: 1
---

**Cumulative Layout Shift measures how much visible content moved, without the person causing it,
over the life of the page.** It is the metric for the button that moved just as somebody tapped it,
and the paragraph that jumped down a line while somebody read it. A shift caused by the person, such
as opening a menu they tapped, does not count: anything within half a second of an interaction is
excused.

## How a shift is scored

Each shift gets a score of two fractions multiplied:

- **impact**: how much of the window the moving content covered, before and after the move together;
- **distance**: how far it moved, as a fraction of the window's larger side.

Content covering half the window that moves down a tenth of it scores about 0.05. The same move
covering the whole window scores about 0.1. So **the same shift scores higher on a small screen**,
where the content that moves covers more of the window and the distance is a larger part of it. The
section "A layout shift, made and removed" measures with a phone-sized window for that reason.

Shifts are grouped into **windows**: shifts less than a second apart join the same window, and a
window lasts five seconds at most. CLS is the score of the worst window, so a page that loads with a
single burst of movement is scored on that burst, however long it stays open afterwards.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Layout shifts along a timeline, each drawn as a bar whose height is its score. Shifts less than a second apart belong to the same window, and a window lasts five seconds at most. Two windows are drawn; CLS is the total of the worse one.\"><line x1=\"40\" y1=\"140\" x2=\"690\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,140.0 682.6,143.1 682.6,136.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"690\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seconds</text><rect x=\"71.0\" y=\"110\" width=\"10\" height=\"30\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"101.0\" y=\"122\" width=\"10\" height=\"18\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"143.0\" y=\"100\" width=\"10\" height=\"40\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"419.0\" y=\"118\" width=\"10\" height=\"22\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"455.0\" y=\"128\" width=\"10\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"64.0\" y=\"40\" width=\"102.0\" height=\"105\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"115.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">window 1: the worst</text><rect x=\"412.0\" y=\"60\" width=\"66.0\" height=\"85\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"445.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">window 2</text><text x=\"40\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"160\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"280\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"400\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"520\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><text x=\"640\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"280\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">more than a second with no shift ends a window</text></svg>", "caption": "CLS is the worst burst of movement, not the sum of every shift the page ever made."}
```

**The threshold is 0.1 for good and 0.25 for poor.** The common causes are all things that arrive
late and take room that nobody kept for them: an image without a width and height (lesson 7), a font
that swaps to a different size (lesson 7), an advertisement, and, in the planner, a notice.
