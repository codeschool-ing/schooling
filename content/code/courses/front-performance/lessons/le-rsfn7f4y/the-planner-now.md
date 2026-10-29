---
title: The planner now
version: 1
---

**The planner began this course as a page drawn in the browser from a JSON file, and every lesson since added one
thing to it, measured before and after.** Read as a list, it is also the order in which a real site's performance
work usually goes:

| lesson | what the planner gained | the number it moved |
|---|---|---|
| 1 | rendering on the server | the first paint of the course page, from 948 to 640 milliseconds with every request slowed |
| 3 | prerendering | a page served as a file, with the cost of a rebuild that grows with the site |
| 4 | hydration from the page, streaming | no second request for the plan; the dead window, measured |
| 5 | the notice sent with the page, less work per click | an LCP a round trip earlier; an INP from 1888 to 88 milliseconds |
| 6 | compression | Lighthouse from 75 to 100 on the large home page |
| 7 | pictures sized and chosen, fonts preloaded, CSS inlined | an LCP of almost forty seconds down to 1.3, and no render-blocking request |
| 8 | the chart loaded on demand | the course page back to twenty kilobytes of script from more than two hundred |
| 9 | cache headers, a CDN | a second visit with no download, and 304s for the rest |
| 10 | a service worker | the planner opens with no network at all |
| 11 | a manifest, icons, a button | installable, and able to show a notification |

## What carries over

**Measure first, change one thing, measure again under the same conditions.** Every row above was a measurement
before it was a fix, and two of the course's findings went against the obvious guess: Lighthouse's model was
pessimistic by three seconds on one page, and the slow script of lesson 6's trace was not slow because of its data.

**Lab numbers find causes; field numbers say whether a fix mattered.** Everything here was measured on one
computer, and the planner sends its Core Web Vitals home since lesson 5. The last word on each row belongs to that
endpoint, read at the 75th percentile, after real people have used the change.

**And a decision written down is not a mistake.** The planner still embeds its whole plan in every page, keeps its
fonts at an address without a hash, and asks nobody for permission to notify them. Each of those is in the lesson
that decided it, with the measurement that would change the decision.
