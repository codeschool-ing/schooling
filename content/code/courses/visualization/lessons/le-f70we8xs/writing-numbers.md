---
title: Writing numbers on charts
version: 1
---

Every number on a chart is read, so each one should be written for a reader rather than copied from a
cell. Four habits cover most of it.

## Round to what the reader can use

**20,586 orders** is right for a table and often too precise for a chart label, where 20.6k or
about 21,000 is what the reader will remember. Use the precision the decision needs: a growth rate
of 60.5% says more than 60.4713%, and 61% may be enough. Keep the same precision across a chart, so
that 60.5% does not sit beside 14%.

## Use the reader's conventions

The same number is written differently in different places:

| | English | Portuguese (Brazil) |
|---|---|---|
| thousands separator | 20,586 | 20.586 |
| decimal separator | 60.5% | 60,5% |
| currency | R$ 1,960 thousand | R$ 1.960 mil |
| dates | Oct 2024 | out. 2024 |

A chart for a Brazilian audience written with English separators makes every reader stop and convert.
**Set the locale in your tool** rather than typing separators by hand; matplotlib, spreadsheets and BI
tools all format by locale. This course's figures change separators between the English and the
Portuguese pages, and its program outputs, which are captures, keep what the program printed.

## Name the unit once, clearly

"R$ thousands" in the axis title, then 412 on the bar, is clearer than "R$ 412,000" on every bar.
**Percent and percentage points are different**: Southeast's growth was 11.3 percentage points
below the company's 25.9%, not 11.3% below it. Lesson 12's map said "pp" for exactly this reason.

## Align and order

In a table beside a chart, **align numbers on the right**, so the digits line up and their size is
visible at a glance, and sort the rows the same way as the chart. A reader moving between the two
should find each row in the same place.
