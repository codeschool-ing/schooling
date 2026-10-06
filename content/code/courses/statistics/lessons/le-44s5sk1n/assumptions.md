---
title: What every test assumes
version: 1
---

A p-value is only as good as the assumptions behind it. The tests in this lesson share a short list, and checking it is part of running them.

## Independence

Every test here assumes that the observations are **independent**: one delivery's time tells you nothing about another's, beyond what the groups explain. This is the assumption that matters most and that no formula can check.

It breaks in recognisable ways. Deliveries on the same rainy evening are slow together. The same customer appearing many times in a sample counts as several observations of one person. Measurements taken one after another drift together. When the data has such structure, a test that ignores it reports more certainty than the data holds. The paired test is the simplest example of using the structure instead of ignoring it.

## Shape

The t tests and ANOVA assume the means are roughly normal, which by the central limit theorem holds for large enough samples, and for small samples needs the data itself to be roughly symmetric without extreme outliers. Lesson 7's tools are the check: a histogram or boxplot of each group. When the shape is doubtful and the sample small, use the rank-based test, or report both.

## Spread

The equal-spread t test and the classical ANOVA assume the groups have similar standard deviations. Welch's t test drops that assumption, which is why it is the default for two groups. For several groups with very different spreads, there is a Welch version of ANOVA as well, and the rank-based test is another option.

## Expected counts

The chi-square test needs expected counts of about 5 or more in each cell. For smaller tables, **Fisher's exact test** computes the p-value directly from the counts without the approximation.

## The order of work

1. Look at the data: boxplots by group, or the table of counts.
2. Check independence by thinking about how the data was collected.
3. Choose the test from the two questions of this lesson's first section.
4. Run it, and if an assumption is doubtful, run the alternative too and see whether the conclusion changes.

A test that survives that order is one a reader can trust. A test chosen because it gave the smallest p-value is lesson 14's garden of forking paths, with a different gate.
