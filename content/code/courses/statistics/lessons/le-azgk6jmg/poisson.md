---
title: The Poisson distribution
version: 1
---

Horta receives an average of 2.4 complaints a day. They do not arrive on a schedule; each one is an independent event, and the day has no fixed number of "trials". How likely is a day with no complaints at all? With five or more?

The **Poisson distribution** models counts of events that happen **at random, independently, at a steady average rate**: complaints per day, orders per minute, typos per page, accidents per month at a junction. It has a single parameter, the average rate **λ** (the Greek letter lambda), and it is named after the French mathematician Siméon Denis Poisson.

## The formula

The probability of exactly *k* events, when the average is λ, is

```localised
P(X = k) = e^(−rate) × rate^k ÷ k!
```

where the rate is λ, *e* is the constant 2.71828… and *k*! is "*k* factorial", 1 × 2 × … × *k*, with 0! = 1.

For λ = 2.4:

| complaints | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| probability | 0.091 | 0.218 | 0.261 | 0.209 | 0.125 | 0.060 | 0.024 | 0.008 |

A day with **no complaints** has probability e^(−2.4) = **0.0907**, about one day in eleven. A day with **five or more** has probability 0.0959, about one day in ten.

```localised
=POISSON.DIST(0, 2.4, FALSE)         0.0907179532894125
=1 - POISSON.DIST(4, 2.4, TRUE)      0.0958685903363992
```

## The mean equals the variance

A Poisson distribution's mean is λ, and so is its **variance**. That gives a quick check on whether count data could be Poisson: compute the mean and the variance and see whether they are close.

Horta's last 60 days of complaints have a mean of 2.18 and a variance of 1.85. Close enough to be plausible. A variance far above the mean — called **overdispersion** — would say the events are not independent: complaints coming in bursts, say, because one bad batch of strawberries upsets twenty customers at once.

## Rates scale with the interval

The rate belongs to an interval, and changes with it. 2.4 complaints a day is 16.8 a week, and the chance of a whole week with no complaint at all is e^(−16.8), about 5 in 100 million. The binomial needed a number of trials; the Poisson needs only a rate and an interval, which is why it fits events that can happen at any moment.
