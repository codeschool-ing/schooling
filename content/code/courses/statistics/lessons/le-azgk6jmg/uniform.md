---
title: The uniform distribution
version: 1
---

The **uniform distribution** gives every value in a range the same chance. It is the model of complete ignorance about where in the range a value will land.

## Continuous: a flat line

A Horta courier will arrive at a random moment between 18:00 and 18:30, with no moment more likely than any other. The density is flat over the half hour and zero outside it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 200\" role=\"img\" data-fig=\"l08-uniform\" aria-label=\"A flat line at height one thirtieth from 0 to 30 minutes: the courier is equally likely to arrive at any moment in the half hour. The stretch from 20 to 30 minutes is shaded; it is a third of the rectangle, so the chance of waiting more than 20 minutes is one in three.\"><path d=\"M50.0 150.0 L520.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M77.6 150.0 L77.6 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"77.6\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M146.8 150.0 L146.8 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"146.8\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M215.9 150.0 L215.9 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"215.9\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M285.0 150.0 L285.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"285.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M354.1 150.0 L354.1 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"354.1\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M423.2 150.0 L423.2 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"423.2\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M492.4 150.0 L492.4 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"492.4\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><text x=\"285.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">minutes after 18:00</text><path d=\"M354.1 150.0 L354.1 71.4 L492.4 71.4 L492.4 150.0 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.45\"></path><path d=\"M77.6 150.0 L77.6 71.4 L492.4 71.4 L492.4 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"423.2\" y=\"57.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">wait longer than 20 minutes: 1/3</text></svg>", "caption": "Every moment equally likely, so the probability of any stretch is its share of the width."}
```

With a flat density, the probability of any stretch is simply its share of the whole width. The chance of waiting more than 20 minutes is the stretch from 20 to 30, a third of the 30-minute window: **1/3**.

For a uniform distribution between *a* and *b*:

- the **mean** is the midpoint, (*a* + *b*) ÷ 2, here 15 minutes;
- the **standard deviation** is (*b* − *a*) ÷ √12, here 30 ÷ √12 = **8.66 minutes**.

The √12 comes out of the calculus and is worth knowing only for one reason: the standard deviation of a flat distribution is a little under 30% of its width.

## Discrete: a fair die

The discrete version gives each of a set of values the same probability. A fair six-sided die gives each face 1/6. A random draw of one order from a list of 400 gives each order 1/400, and that is exactly what a **simple random sample** relies on, as lesson 10 explains.

## Where it fits and where it does not

The uniform is the right model when nothing favours one value over another: the second hand of a clock when you glance at it, a random number generator, a fair lottery.

It is the wrong model whenever values cluster. Delivery times, baskets, weights and almost everything measured in business data have a peak somewhere, and assuming every value equally likely would ignore it. Uniform data is rare in the wild, which is partly why its appearance — a column of "random" survey answers spread perfectly evenly — is sometimes a sign that somebody made the data up.
