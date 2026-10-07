---
title: Three kinds of outlier
version: 1
---

An **outlier** is an observation that lies unusually far from the others. That definition is deliberately vague, because "unusually far" depends on the data, and the rest of this lesson is about making it precise. What matters first is that an outlier is a **question**, not a verdict. It asks: why is this value here?

There are three common answers, and they call for three different responses.

## A mistake

The value does not describe anything real. A decimal point slipped and R$ 212.60 became R$ 2,126.00. A delivery time was recorded in seconds instead of minutes. A test order of R$ 0.01, placed by a developer checking the payment page, ended up in the sales table.

Mistakes are the easy case, in principle: they should be **corrected**, and if the true value cannot be recovered, removed. In practice the difficulty is proving it is a mistake. R$ 2,126.00 might be a typo or might be a real order, and the number alone cannot tell you which.

## A visitor from another population

The value is real, but it belongs to a different group from the one being studied. Horta sells to households. One month a restaurant orders 80 kg of tomatoes and a crate of oil: a real order, correctly recorded, from a customer who is not the kind of customer the analysis is about.

Visitors should usually be **analysed separately**. Mixing a restaurant's purchases with households' would distort what a typical household spends, and leaving them out entirely would lose the fact that restaurants are buying. Separating them is often the most useful thing an outlier reveals: lesson 7 made the same point about two peaks.

## A genuine extreme

The value is real and belongs to the same population. A family doing its year-end shop spends R$ 421.78. A delivery on a rainy evening, carrying fourteen items, takes 45.5 minutes in a neighbourhood where 30 is normal.

Genuine extremes should be **kept**. They are part of the population, and any honest description of the population includes them. Lesson 4 showed what happens to a payroll budget that leaves out the founder: it bounces.

## The order of the questions

The useful habit is to ask the questions in order. Could this be a mistake? Check the source. If it is real, does it belong to the population I am describing? If it does, it stays. Most of the work is in the checking, and the next sections give you the tools for finding the candidates to check.
