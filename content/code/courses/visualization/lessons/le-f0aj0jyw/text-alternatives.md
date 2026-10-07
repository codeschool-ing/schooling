---
title: Text alternatives
version: 1
---

A chart on a web page, in a report or in an e-mail is an image to a screen reader. A person who is
blind, or who uses a screen reader for any reason, gets **only the text that describes it**. WCAG's
criterion **1.1.1, Non-text Content**, asks that every image that carries information has such a text.

## What the alternative should say

Not "chart". Not "bar chart of growth by region". Both are true and neither gives the reader what the
chart gives a sighted one. A good text alternative states:

1. **what kind of chart and what it measures**, in one clause;
2. **the main finding**, the sentence the chart was made to show;
3. **the key values**, the few numbers a reader would quote.

For lesson 13's highlight chart:

> Bar chart of growth in orders from 2024 to 2025 by region. North grew fastest, at 60.5%, four times
> Southeast's 14.6%. Northeast 44.8%, Centre-West 30.0%, South 23.5%.

Every figure in this course carries a description written this way, in the page's markup, which a
screen reader announces in place of the drawing.

## When the chart is complex

A short alternative cannot hold a heatmap of 105 cells or a map of 27 states. For those, **give the
data as a table** beside the chart or behind a link, and keep the alternative to the finding. A table
is also the best alternative for any reader who needs exact numbers, so it rarely goes to waste.

## Where to put it

- **On the web**, the image's `alt` attribute, or `aria-label` on an inline SVG.
- **In Word, PowerPoint and PDF**, the image's alt text field; most office software prompts for it.
- **In BI tools**, Power BI and Tableau let you write alt text for each visual, and Power BI can build
  it from the data with a formula, so the numbers stay current.
- **In e-mail and chat**, a sentence under the image, which also helps everyone reading on a phone with
  images switched off.
