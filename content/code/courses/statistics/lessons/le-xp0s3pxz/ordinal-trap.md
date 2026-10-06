---
title: The average of a star rating
version: 1
---

Horta asks every customer to rate the delivery from 1 to 5 stars. Across the twelve orders the
ratings were:

| stars | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| orders | 1 | 1 | 2 | 4 | 4 |

Every app shows the average: 45 stars over 12 orders is **3.75**. Is that a fair summary?

## What the average assumes

To add star ratings and divide, you have to treat them as amounts. That means assuming **the steps
are the same size**: that the difference between 1 and 2 stars is as big as the difference between 4
and 5. Nobody established that. The customer chose a word — terrible, poor, fine, good, excellent —
and the app turned it into a digit.

Plenty of people use only the ends of the scale, 5 for "nothing went wrong" and 1 for "something
did". For them the distance from 4 to 5 is small, and the distance from 1 to 2 is enormous. Averaging
their ratings mixes two different rulers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 260\" role=\"img\" data-fig=\"l02-ratings-bars\" aria-label=\"A bar chart of the twelve ratings, from 1 to 5 stars: one 1, one 2, two 3s, four 4s and four 5s. The median, 4, is a rating somebody gave. The mean, 3.75, sits between two bars.\"><path d=\"M80.0 50.0 L80.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 205.0 L80.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 174.0 L520.0 174.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 174.0 L80.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"174.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M80.0 143.0 L520.0 143.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 143.0 L80.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"143.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M80.0 112.0 L520.0 112.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 112.0 L80.0 112.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M80.0 81.0 L520.0 81.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 81.0 L80.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"81.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M80.0 50.0 L520.0 50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 50.0 L80.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"80.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><path d=\"M95.8 205.0 L95.8 174.0 L152.2 174.0 L152.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"124.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><path d=\"M183.8 205.0 L183.8 174.0 L240.2 174.0 L240.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"212.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2</text><path d=\"M271.8 205.0 L271.8 143.0 L328.2 143.0 L328.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"300.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><path d=\"M359.8 205.0 L359.8 81.0 L416.2 81.0 L416.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"388.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4</text><path d=\"M447.8 205.0 L447.8 81.0 L504.2 81.0 L504.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"476.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5</text><path d=\"M80.0 205.0 L520.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"300.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">stars given</text><path d=\"M388.0 205.0 L388.0 36.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"388.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">median 4</text><path d=\"M366.0 205.0 L366.0 36.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"366.0\" y=\"28.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">mean 3.75</text></svg>", "caption": "The median is a value on the scale. The mean treats the step from 1 star to 2 as the same size as the step from 4 to 5, which nobody measured."}
```

## What is safe to report

The **median** needs only the order. Sort the twelve ratings — 1, 2, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5 —
and the middle two are both 4, so the median is 4. That is a rating somebody actually gave, and it
says that half the customers rated the delivery 4 or better.

The **distribution itself** is safer still. "Eight of twelve customers gave 4 or 5 stars; one gave
1" says more than any single number, and it assumes nothing about distances.

## Then why does everybody average ratings?

Because it is convenient, and because with many ratings it often gives the same ranking as a more
careful method. Treating a five-point scale as if it were interval is a common practice in survey
research, and a defensible one when the scale has enough points and the responses spread across
them.

The point is not that the 3.75 is forbidden. It is that **it rests on an assumption**, and the
assumption breaks in a recognisable way: when two products have the same average built from very
different distributions. A 3.75 made of mostly 4s and a 3.75 made of 5s and 1s describe different
services, and only the distribution shows the difference.
