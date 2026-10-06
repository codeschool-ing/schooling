---
title: The mode
version: 1
---

The **mode** is the value that occurs most often. It is the only summary of centre that works for every scale, nominal included, because finding it needs nothing but counting.

For *payment*, the mode is `pix`, with 6 of the 12 orders. For *items*, sorted as

```localised
1   2   3   3   4   5   6   7   8   9   12   15
```

the mode is **3**, the only value that appears twice.

## More than one mode

Horta's star ratings are 1, 2, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5. Both 4 and 5 appear four times, and nothing appears more often. The ratings have **two modes**, and saying only one of them would misreport the data. A variable with two modes is called **bimodal**.

A bimodal variable often means two groups mixed together. If Horta's customers split into people who rate everything 5 unless something goes wrong and people who reserve 5 for the exceptional, their ratings would pile up at two places. Lesson 7 returns to two peaks as a shape of a whole distribution.

## No mode at all

The twelve delivery times are all different, so every value occurs once and there is no mode. That is typical of continuous variables measured finely: with enough precision, no two values coincide.

For a continuous variable, the useful version of the mode comes from grouping. Put the times into intervals of five minutes — 25 to 30, 30 to 35, and so on — and the interval with the most deliveries is the **modal class**. Here, 30 to 35 and 35 to 40 hold three deliveries each, and 25 to 30 holds two, so the times are crowded between 30 and 40 minutes.

## When the mode is the answer

The mode answers "what happens most often?", which is sometimes exactly the question.

- A shop deciding which bag size to stock wants the most common order size, not the mean of 6.25 items.
- A survey reporting the most popular answer wants the mode.
- A categorical variable has no other centre.

It is the weakest of the three for numerical data with many distinct values, and the only one available for names.
