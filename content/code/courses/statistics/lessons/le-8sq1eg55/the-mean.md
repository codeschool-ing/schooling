---
title: The mean
version: 1
---

The **mean** is what most people call the average: add the values and divide by how many there are.

For Horta's twelve delivery times:

```localised
34.5 + 41.0 + 52.5 + 29.0 + 38.5 + 44.0 + 31.5 + 61.0 + 36.0 + 27.5 + 39.0 + 33.0 = 467.5
467.5 ÷ 12 = 38.958…
```

The mean delivery time is **38.96 minutes**, to two decimal places.

Written as a formula, with *n* values called *x*₁ to *xₙ*, the mean is *x̄* = (*x*₁ + *x*₂ + … + *xₙ*) ÷ *n*.
The bar over the *x* is read "x-bar" and is the usual symbol for the mean of a sample. Lesson 10 explains why a sample's mean gets a different symbol from a population's.

## The fair share

One way to read the mean is as a fair share. If every one of the twelve deliveries had taken the same time, and the total of 467.5 minutes stayed the same, each would have taken 38.96 minutes.

That reading explains when the mean is the right summary: **when the total matters**. If Horta pays couriers by the minute, the mean time multiplied by the number of deliveries is the wage bill, exactly. No other summary has that property.

## The balance point

The other way to read it is physical. Put each value as a weight on a ruler, and the mean is the point where the ruler balances.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 200\" role=\"img\" data-fig=\"l03-balance\" aria-label=\"The twelve delivery times as dots on a line, resting on a fulcrum at the mean, 38.96 minutes. The distances below the mean add up to 42.71 and the distances above it add up to the same.\"><path d=\"M40.0 120.0 L600.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40.0 120.0 L40.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"40.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M110.0 120.0 L110.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"110.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M180.0 120.0 L180.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"180.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35</text><path d=\"M250.0 120.0 L250.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"250.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M320.0 120.0 L320.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"320.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">45</text><path d=\"M390.0 120.0 L390.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"390.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M460.0 120.0 L460.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"460.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">55</text><path d=\"M530.0 120.0 L530.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"530.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M600.0 120.0 L600.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"600.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">65</text><text x=\"320.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">delivery time, in minutes</text><circle cx=\"75.0\" cy=\"98.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"96.0\" cy=\"98.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"131.0\" cy=\"98.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"152.0\" cy=\"98.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"173.0\" cy=\"98.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"194.0\" cy=\"98.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"229.0\" cy=\"98.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"236.0\" cy=\"84.0\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"264.0\" cy=\"98.0\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"306.0\" cy=\"98.0\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"425.0\" cy=\"98.0\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"544.0\" cy=\"98.0\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M226.4 120.0 L235.4 107.0 L244.4 120.0 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><text x=\"235.4\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">mean 38.96</text><text x=\"54.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">distances below: 42.71</text><text x=\"586.0\" y=\"52.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">distances above: 42.71</text></svg>", "caption": "The mean is the point where the line would balance. Two far values on the right are balanced by many near ones on the left."}
```

The distances from the mean to the values below it add up to exactly the same as the distances to the values above it, 42.71 on each side here. That is not a coincidence of these numbers. It is what the mean is: **the deviations from the mean always add up to zero**.

The picture also shows the mean's weakness. The two slow deliveries, at 52.5 and 61 minutes, sit far out on the right, and far weights pull hard on a balance. They drag the mean towards them. Seven of the twelve deliveries took less than the mean. Lesson 4 is about what happens when one value pulls much harder than these two.

## A mean need not be a value anyone had

No delivery took 38.96 minutes. The mean number of items per order is 6.25, and no order held a quarter of an item. That is normal. The mean describes the set as a whole, and nothing obliges any single member to sit on it.
