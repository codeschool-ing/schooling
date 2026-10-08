---
title: Categorical palettes
version: 1
---

A categorical palette has one job: **make each category easy to tell apart without suggesting that
any is more important**. That rules out the obvious approach of picking colours one by one from a
picker.

## What a good one does

- **Distinct hues.** Each colour sits clearly apart on the hue circle from its neighbours.
- **Similar weight.** No colour is so much lighter, darker or more saturated than the rest that it
  looks like the important one. Lesson 11 showed why "the same HSL lightness" does not achieve this.
- **Safe for colour blindness.** The commonest forms make red and green hard to tell apart, so a
  palette that relies on that pair fails for about one man in twelve (lesson 14).

The palette in the first row of the previous figure is **Okabe and Ito's**, published in 2008 for
scientific figures and designed to stay distinct for the common forms of colour blindness. Its eight
colours are a good default whenever a tool lets you choose:

| | hex | | hex |
|---|---|---|---|
| orange | `#E69F00` | blue | `#0072B2` |
| sky blue | `#56B4E9` | vermilion | `#D55E00` |
| bluish green | `#009E73` | reddish purple | `#CC79A7` |
| yellow | `#F0E442` | black | `#000000` |

## How many categories

**Few.** People can tell about six to eight hues apart quickly and match them to a legend reliably.
Past that, colours start to blur and the legend becomes a lookup table. With more categories:

- **highlight the few that matter** and put the rest in grey, which lesson 13 is about;
- **merge the small ones** into "other";
- **split the chart** into small multiples (lesson 10), where the panel title replaces the colour.

## Keep colours attached to their categories

Once a region has a colour, **it keeps it in every chart of the report**. If the Northeast is orange
on page one and blue on page three, a reader who learnt the first will misread the second. Lesson 13
returns to this as consistency.
