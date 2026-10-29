---
title: Good, needs improvement, poor
version: 1
---

**Each metric has two thresholds, which divide every measurement into good, needs improvement and
poor.** They are not written in a standard; they are Google's, and the `web-vitals` library carries
them as constants. This course installs it in the next section; once it is there, the numbers can be
read straight out of the code that applies them:

```
ana@dev:~/planner$ grep -h 'Thresholds = ' node_modules/web-vitals/dist/modules/on*.js
export const CLSThresholds = [0.1, 0.25];
export const FCPThresholds = [1800, 3000];
export const INPThresholds = [200, 500];
export const LCPThresholds = [2500, 4000];
export const TTFBThresholds = [800, 1800];
```

LCP and INP are in milliseconds and CLS has no unit. The library also defines thresholds for first
contentful paint and for the time to first byte, which are not Core Web Vitals but help explain an
LCP.

## A page is judged at the 75th percentile

**A page passes when three quarters of its visits are good**, measured separately for each metric
and separately for phones and for desktops. The 75th percentile is a compromise written into the
definition: the median would let half the visitors have a bad time, and the slowest one per cent is
often a broken network that no page could help.

So a single measurement on your own computer cannot tell you whether a page passes. It tells you how
one visit went. **The thresholds are for field data**: values sent from many real browsers, which
is what the section "Field data: the number from the visitor" collects. What a measurement here is
good for is finding a cause, changing it, and measuring again under the same conditions, which is
what the next three sections do.

## What the numbers do not say

**A good score is not a fast page; it is a page that is not slow in these three ways.** It says
nothing of how long a search takes to answer, how quickly the next page appears after a click on a
link that does a full navigation, or whether the page works at all on a network that drops. Those
are measured with the tools of lesson 6, against goals the team sets for its own pages.
