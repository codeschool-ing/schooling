---
title: Twenty tests on nothing
version: 1
---

A significance level of 5% means that, when the null hypothesis is true, 5% of tests reject it anyway. One test at a time, that is a sensible risk. Many tests at once, it is a near certainty of being fooled.

## Twenty tweaks that do nothing

Imagine Horta's marketing team tries twenty small changes to the website — a new button colour, a different photo, a reworded offer — and for each one compares the baskets of 50 visitors who saw the change with 50 who did not. Suppose none of the changes does anything. Each test has a 5% chance of a "significant" result by accident.

The chance that **at least one** of the twenty comes out significant is

```localised
1 − 0.95^20 = 0.64
```

Nearly two chances in three of a "finding", from changes that do nothing.

To see it, here are 1,000 simulated batches of 20 such tests, each test comparing two groups of 50 baskets drawn from the same 400, so that every null is true:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 270\" role=\"img\" data-fig=\"l14-batches\" aria-label=\"A bar chart of 1,000 batches of 20 tests, every test comparing two groups that differ by nothing but chance. 372 batches had no significant result, 394 had one, 174 had two, 47 had three and 13 had four or more. Dots show what the binomial distribution predicts, and they sit close to the bars.\"><path d=\"M70.0 50.0 L70.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 210.0 L70.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 174.4 L570.0 174.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 174.4 L70.0 174.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"174.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M70.0 138.9 L570.0 138.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 138.9 L70.0 138.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"138.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M70.0 103.3 L570.0 103.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 103.3 L70.0 103.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"103.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M70.0 67.8 L570.0 67.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 67.8 L70.0 67.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"67.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><text x=\"70.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">batches</text><path d=\"M98.8 210.0 L98.8 77.7 L156.5 77.7 L156.5 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"127.7\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">0</text><circle cx=\"127.7\" cy=\"82.5\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M195.0 210.0 L195.0 69.9 L252.7 69.9 L252.7 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"223.8\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><circle cx=\"223.8\" cy=\"75.8\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M291.2 210.0 L291.2 148.1 L348.8 148.1 L348.8 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"320.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2</text><circle cx=\"320.0\" cy=\"142.9\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M387.3 210.0 L387.3 193.3 L445.0 193.3 L445.0 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"416.2\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><circle cx=\"416.2\" cy=\"188.8\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M483.5 210.0 L483.5 205.4 L541.2 205.4 L541.2 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"512.3\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4+</text><circle cx=\"512.3\" cy=\"204.3\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M70.0 210.0 L570.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"320.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tests in the batch with p below 0.05</text><path d=\"M380 30 L394 30 L394 42 L380 42 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"400.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">simulated batches</text><circle cx=\"387.0\" cy=\"56.0\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"400.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">binomial, 20 tests at 5%</text></svg>", "caption": "Run twenty tests on nothing, and most of the time at least one comes out \"significant\". In 628 of the 1,000 batches, somebody would have had a finding."}
```

In **628 of the 1,000 batches**, at least one test was significant. Across all 20,000 tests, 936 were significant: 4.7%, about the 5% the significance level promises. Every test behaved correctly, and the team that ran twenty of them would usually have had a result to announce.

## How it happens without anybody cheating

Nobody needs to fake anything. It is enough to:

- test many outcomes and report the one that came out significant;
- test many subgroups — by neighbourhood, by day, by device — and report the one that worked;
- try several ways of handling outliers and keep the one that gives the smallest p;
- keep collecting data and test after every batch, stopping when p dips below 0.05.

Each choice looks reasonable on its own. Together they are called **p-hacking**, or the "garden of forking paths", and they turn a 5% false-alarm rate into something much higher.

## The defences

**Decide in advance.** Write down the hypothesis, the outcome, the test and the sample size before collecting the data. Lesson 9 made the same argument about outliers: a decision made before the result cannot drift towards it.

**Report everything tested.** "One of the twenty tweaks reached p = 0.03" is a very different finding from "the new button reached p = 0.03", and a reader needs to know which one they are reading.

**Adjust for multiple tests.** The simplest correction, named after the mathematician Carlo Emilio **Bonferroni**, divides α by the number of tests. For 20 tests at an overall 5%, each test must reach p < 0.05 ÷ 20 = **0.0025**. It is conservative, and it keeps the chance of any false alarm in the batch near 5%.

**Replicate.** A real effect turns up again in fresh data. A false alarm usually does not.
