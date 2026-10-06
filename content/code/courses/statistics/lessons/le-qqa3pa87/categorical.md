---
title: Categorical variables
version: 1
---

A **categorical variable** puts each observation into one of a set of groups. Horta's *payment* column
is one: every order went into exactly one of `pix`, `card` or `cash`. *neighbourhood* is another, with
four groups in these twelve rows.

The groups are called **categories**, or levels. The test for a categorical variable is simple:
the value answers the question *which one?* rather than *how much?*

## What you can do with categories

You can **count** them. Six orders were paid by pix, four by card and two in cash. Divide by the
twelve orders and the counts become **shares**: half by pix, a third by card and a sixth in cash.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 520 250\" role=\"img\" data-fig=\"l01-payment-bars\" aria-label=\"A bar chart of how the twelve orders were paid: pix 6, card 4, cash 2. The bars stand apart because the categories have no order and nothing lies between them.\"><path d=\"M90.0 40.0 L90.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M86.0 200.0 L90.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M90.0 177.1 L480.0 177.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 177.1 L90.0 177.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"177.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M90.0 154.3 L480.0 154.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 154.3 L90.0 154.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"154.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M90.0 131.4 L480.0 131.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 131.4 L90.0 131.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"131.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M90.0 108.6 L480.0 108.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 108.6 L90.0 108.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"108.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M90.0 85.7 L480.0 85.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 85.7 L90.0 85.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"85.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M90.0 62.9 L480.0 62.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 62.9 L90.0 62.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"62.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M90.0 40.0 L480.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 40.0 L90.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"90.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><path d=\"M116.0 200.0 L116.0 62.9 L194.0 62.9 L194.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"155.0\" y=\"52.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"155.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pix</text><path d=\"M246.0 200.0 L246.0 108.6 L324.0 108.6 L324.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"285.0\" y=\"98.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"285.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">card</text><path d=\"M376.0 200.0 L376.0 154.3 L454.0 154.3 L454.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"415.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"415.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cash</text><path d=\"M90.0 200.0 L480.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"285.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">how the order was paid</text></svg>", "caption": "Each bar is a count. The gaps say that nothing lies between two categories, and the order of the bars is a choice — here, largest first."}
```

You can say which category is the most common. That is called the **mode**, and lesson 3 gives it a
proper place beside the mean and the median. For *payment* the mode is `pix`.

And that is close to the end of the list. There is no average payment method and no total
neighbourhood, because adding `pix` to `card` has no meaning. Every summary of a categorical
variable starts from a count.

## Categories must not overlap, and must cover everything

Two properties make a categorical variable usable, and both fail quietly when nobody checks.

**Each observation belongs to one category only.** If the form let a customer tick both "pix" and
"card" for one order, the counts would add up to more than the number of orders, and a share of 60%
next to one of 50% would stop meaning anything.

**Every observation belongs to some category.** A real column almost always needs an `other` or a
`not recorded`. Without one, the orders that fit nowhere get forced into the nearest category, or
dropped, and either way the count is wrong without anything looking wrong.

## A category written two ways is two categories

A computer compares values letter by letter. If one person types `Pix`, another `pix` and a third
`PIX`, the computer counts three categories, each smaller than the truth. Barão Geraldo typed once
with the accent and once without becomes two neighbourhoods.

This is the commonest fault in real categorical data, and the course `data-cleaning` deals with it
at length. Here it is enough to know the symptom: **a frequency table with more categories than
the world has** is a frequency table that needs cleaning before anybody reads it.
