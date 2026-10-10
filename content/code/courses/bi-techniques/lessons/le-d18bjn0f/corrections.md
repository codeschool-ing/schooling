---
title: Correcting for many comparisons
version: 1
---

When many comparisons are made and each one is reported as a finding, the significance threshold
has to be tightened to keep the total risk of a false alarm where it was meant to be. Three
corrections cover almost every case.

## Bonferroni

**Divide the significance level by the number of comparisons.** Nine segments at 5 per cent each
need p below 0.05 / 9, about 0.0056. Equivalently, multiply each p-value by nine and compare it with
0.05. Panela's mobile segment, at p = 0.006, misses by a hair. Bonferroni guarantees that the chance
of even one false alarm across all nine stays at or below 5 per cent, and it is easy to explain. It
is also strict: with many comparisons it misses real effects.

## Holm

**Bonferroni applied in steps.** Sort the p-values from smallest to largest. Compare the smallest
with 0.05 / 9, the next with 0.05 / 8, and so on, stopping at the first that fails. It gives the same
guarantee as Bonferroni and never finds fewer effects, so there is little reason to prefer
Bonferroni when software does the arithmetic. It is what the program of the last section used: the
mobile segment's p of 0.006, multiplied by nine, became 0.056.

## False discovery rate

When the comparisons are many, hundreds of metrics or thousands of products, guaranteeing zero false
alarms is too strict to be useful. **The false discovery rate**, controlled by the Benjamini-Hochberg
method (`method="fdr_bh"` in `multipletests`), accepts that some of the findings will be false and
keeps their share below a chosen level, such as 10 per cent. It answers a different question: not
"is anything here a false alarm?" but "what share of what I am calling real is not?".

## Which to use

| situation | correction |
|---|---|
| one primary metric decided in advance | none: that is the point of choosing it |
| a handful of secondary metrics or segments, each reported as a finding | Holm |
| a large screening, to choose what to test next | false discovery rate |
| exploring the data to generate ideas | none, and nothing reported as a finding |

The last row matters most. Slicing a test to look for ideas is useful, as long as what comes out is
labelled as ideas.
