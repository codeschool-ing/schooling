---
title: Type I and type II errors
version: 1
---

A hypothesis test ends with a decision, and the truth it is deciding about is unknown. Put the two side by side and there are four possibilities:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 230\" role=\"img\" data-fig=\"l15-errors\" aria-label=\"A two-by-two table. Columns: the test rejects the null, or does not. Rows: in truth there is no effect, or there is one. No effect and rejected: a type I error, a false alarm, with probability alpha. No effect and not rejected: correct. A real effect and rejected: correct, with probability equal to the power. A real effect and not rejected: a type II error, a missed effect, with probability beta.\"><text x=\"297.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the test rejects the null</text><text x=\"512.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the test keeps the null</text><text x=\"20.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in truth, no effect</text><rect x=\"194.0\" y=\"40.0\" width=\"207.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"297.5\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">type I error</text><text x=\"297.5\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a false alarm: α</text><rect x=\"409.0\" y=\"40.0\" width=\"207.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"512.5\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">correct</text><text x=\"512.5\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">probability 1 − α</text><text x=\"20.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in truth, a real effect</text><rect x=\"194.0\" y=\"120.0\" width=\"207.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"297.5\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">correct</text><text x=\"297.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the power: 1 − β</text><rect x=\"409.0\" y=\"120.0\" width=\"207.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"512.5\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">type II error</text><text x=\"512.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a missed effect: β</text></svg>", "caption": "Two ways to be right and two ways to be wrong. α is chosen; β depends on how big the effect is and how much data there is."}
```

## The type I error: a false alarm

The null hypothesis is true — there is no effect — and the test rejects it anyway. This is a **type I error**, and its probability is **α**, the significance level. At α = 0.05, a test of a true null cries wolf one time in twenty. Lesson 14's simulation showed it happening: across 20,000 tests of changes that did nothing, 4.7% came out significant.

The type I error is the one the test is built to control. You choose its rate in advance.

## The type II error: a missed effect

The null hypothesis is false — there is a real effect — and the test fails to reject it. This is a **type II error**, and its probability is written **β** (beta).

Unlike α, β is not chosen. It depends on things outside the test's control: **how big the real effect is**, **how noisy the data is** and **how much data there is**. A large effect measured on a big, quiet sample is hard to miss; a small effect measured on a few noisy observations is easy to miss.

## Which error is worse depends on the decision

- A **smoke alarm** is tuned to have many false alarms and very few misses, because a missed fire is a catastrophe and a false alarm is burnt toast.
- A **court** is tuned the other way: convicting an innocent person, a false alarm, is treated as worse than acquitting a guilty one, a miss.
- **Horta's routing trial**: a false alarm would mean paying for a system that does nothing; a miss would mean turning down one that saves time on every delivery. Which costs more is a business question, and the answer should shape the test.

## The two are linked

For a fixed sample, lowering α raises β. A stricter threshold makes false alarms rarer and misses more common, because the line that separates "reject" from "keep" moves further from the null, and real but modest effects end up on the wrong side of it more often. The next section draws that trade.
