---
title: Nominal, ordinal, interval and ratio
version: 1
---

In 1946 the psychologist Stanley Smith Stevens proposed sorting every measurement into one of four
**levels of measurement**. The scheme is old and has its critics, and it is still the clearest way
to decide which arithmetic a column can take.

Each level allows everything the level below it allows, and adds one thing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 260\" role=\"img\" data-fig=\"l02-scales-ladder\" aria-label=\"Four boxes stacked like a ladder. Nominal at the bottom allows equal or different. Ordinal adds greater or smaller. Interval adds differences. Ratio at the top adds ratios, because only it has a true zero. Each rung keeps everything below it.\"><text x=\"26.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">scale</text><text x=\"156.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">what it adds</text><text x=\"316.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">allows</text><text x=\"406.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">Horta’s example</text><rect x=\"16.0\" y=\"38.0\" width=\"648.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"26.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ratio</text><text x=\"156.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a true zero</text><text x=\"316.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">× ÷</text><text x=\"406.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">weight, basket, minutes</text><rect x=\"16.0\" y=\"91.0\" width=\"648.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">interval</text><text x=\"156.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">equal steps</text><text x=\"316.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">+ −</text><text x=\"406.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">°C, calendar year</text><rect x=\"16.0\" y=\"144.0\" width=\"648.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ordinal</text><text x=\"156.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">an order</text><text x=\"316.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">&lt; &gt;</text><text x=\"406.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rating 1 to 5, size S M L</text><rect x=\"16.0\" y=\"197.0\" width=\"648.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">nominal</text><text x=\"156.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">names only</text><text x=\"316.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">= ≠</text><text x=\"406.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">payment, neighbourhood</text></svg>", "caption": "Each rung keeps every operation of the rungs below it and adds one. A rating can be ordered but not subtracted; a temperature can be subtracted but not divided."}
```

## Nominal: names only

A **nominal** variable has categories with no order. *payment* is nominal: pix is not more or less
than card. The only comparison that means anything is *same or different*. You can count, take shares
and find the mode.

## Ordinal: an order, but not distances

An **ordinal** variable has categories with a natural order. A rating of 1 to 5 stars is ordinal, and
so are clothing sizes S, M, L and the answers "never, sometimes, often, always". You can now say that
one value is greater than another, so the **median** becomes available: put the values in order and
take the middle one.

What you cannot say is how far apart two values are. The next section is about that gap, because it
is where most mistakes with ratings happen.

## Interval: equal steps, no true zero

An **interval** variable has equal distances between values, so differences mean something. A
temperature in degrees Celsius is the usual example: from 20 °C to 25 °C is the same rise as from 10
°C to 15 °C. Subtraction is now allowed, and so is the **mean**.

But the zero is arbitrary. 0 °C is where water freezes, a convenient point and not the absence of
temperature. Without a real zero, ratios lie. The section after next shows how.

## Ratio: a true zero

A **ratio** variable has equal steps and a zero that means *none of it*. A basket of R$ 0 holds no
money; a delivery of 0 minutes took no time; an order of 0 kg weighs nothing. Now ratios work: a
basket of R$ 80 is twice one of R$ 40, and a delivery of 60 minutes took twice as long as one of 30.

Most quantities in business data are on a ratio scale: money, time, counts, weights, distances. That
is why the interval scale feels rare. Temperature in Celsius and calendar years are almost the
only interval variables you will meet in practice.

## Categorical and numerical, again

Lesson 1's two families map onto the four levels. **Categorical** variables are nominal or ordinal.
**Numerical** variables are interval or ratio. The four levels split each family in two, and the
split inside each family is the one that catches people.
