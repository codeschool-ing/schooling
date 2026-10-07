---
title: Axes, units and the words around them
version: 1
---

An axis title answers the question "what is this number?", and a number without its unit answers
nothing. **Orders, minutes, reais, per cent, per thousand people**: the unit belongs on the chart,
every time, because the reader has no other way to know.

## What every axis needs

- **What is measured, and in what unit**: "delivery time (minutes)", "revenue (R$ thousands)". If the
  unit is scaled, say so: thousands, millions.
- **Enough ticks to read values, and no more.** Four to six ticks on most axes. Round numbers: 0, 20,
  40, 60, not 0, 17, 34, 51.
- **A time axis labelled as dates people use.** "Jan 2024, Jul, Jan 2025", not "2024-01-01T00:00:00".

## What can go

Text that repeats what the reader already knows is noise. Lesson 17 is about removing noise; three
cases are worth naming here.

- **An axis title that the title already states.** If the title says "monthly orders", the vertical
  axis can say "orders" or nothing.
- **A category axis title** like "Region" above a list of regions. The names explain themselves.
- **Both axis lines and gridlines at full strength.** Keep the baseline; make gridlines quiet or remove
  them.

## Rotate the chart, not the text

Lesson 3 said it for bars and it holds everywhere: **text should be horizontal**. A vertical axis title
rotated 90 degrees is read by tilting the head. Put the axis title above the axis, horizontally, at
the top left, where the eye starts anyway. Every figure in this course does that, and matplotlib needs
two lines to do it instead of the rotated default.

## The subtitle and the source

Beneath a claim title, a quieter **subtitle** carries the label: what, where, when, unit. At the bottom,
a **source line** says where the data came from: "Source: Horta orders, January 2024 to December
2025". Neither is decoration. A chart with no source cannot be checked, and a chart that cannot be
checked asks to be believed.
