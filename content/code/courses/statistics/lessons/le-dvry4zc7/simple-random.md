---
title: The simple random sample
version: 1
---

A **simple random sample** gives every member of the population the same chance of being chosen, and every group of the same size the same chance too. It is the standard against which every other method is judged.

## How it is done

The practical recipe needs a list of the population, called the **sampling frame**:

1. Number every member of the list.
2. Draw the required number of distinct numbers at random.
3. The members with those numbers are the sample.

In a spreadsheet: put `=RAND()` beside each row, sort by that column, and take the first *n* rows. Every ordering is equally likely, so every set of *n* rows is too.

The word "random" here is technical. It does not mean haphazard or arbitrary; it means a **chance mechanism** decided, not a person. Somebody picking "a random-looking" set of customers from a list will, without meaning to, pick the ones whose names catch the eye, the ones near the top, the ones they recognise.

## Random samples differ from each other

Treat the 400 baskets as a population, with a mean of R$ 82.78, and draw three simple random samples of 40. Their means come out at R$ 89.32, R$ 80.03 and R$ 72.47.

Nothing went wrong: **sample statistics vary**. Draw 1,000 samples of 40 and their means spread from R$ 61.53 to R$ 116.79, with a standard deviation of R$ 8.69. Lesson 11 shows the shape of that spread, and lesson 12 turns its width into a margin of error.

The important property is in the centre: across the 1,000 samples, the means average R$ 82.96, very close to the population's R$ 82.78. A simple random sample is **unbiased**: it does not lean in any direction. Individual samples miss, by amounts that can be calculated, but they miss in both directions equally.

## With and without replacement

A sample can be drawn **without replacement**, so nobody is chosen twice, or **with replacement**, putting each chosen member back before the next draw. Real surveys draw without replacement: nobody wants to interview the same household twice. Most formulas in this course assume with replacement, because it makes the draws independent. When the sample is a small fraction of the population, under about 5%, the difference is negligible, and that covers nearly every practical case.

## What it needs

The recipe has one demanding ingredient: **the list**. A simple random sample of Horta's customers needs the customer list. A simple random sample of all households in Campinas needs a list of all households in Campinas, which does not exist in one place. When the list leaves people out, the sample cannot include them, however random the draw. The section on bias returns to this.
