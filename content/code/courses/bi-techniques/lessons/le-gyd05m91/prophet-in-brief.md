---
title: Prophet in brief
version: 1
---

**Prophet** is a forecasting library released by Facebook in 2017 for analysts rather than
statisticians, and it is common in BI teams. It writes a series as a sum of pieces fitted together:

- a **trend** that is a straight line allowed to bend at **changepoints**, places where the growth
  rate changes, which Prophet finds by itself or is told;
- **seasons** drawn as smooth curves, yearly and weekly, which suits daily data with several
  seasons at once;
- **holidays**, given as a list of dates with a window around each, so a moving holiday such as
  Carnival gets its own effect wherever it falls;
- extra **regressors**, other series the forecast may use, such as a marketing budget.

Two of those pieces fix problems this course has already met. Changepoints are a way to handle a
sudden change of level like Panela's price rise, and the holiday list is the cure for the moving
Carnival that both models of this lesson got wrong.

**This course does not install it, and nothing in this section was run.** Prophet fits its model
with a separate statistical engine, Stan, so it is a heavier installation than everything else in
the course put together, and a common place for a setup to fail. Everything it does can be done with the tools
you already have, and lesson 6 does the holiday part with statsmodels. If your team uses Prophet,
the vocabulary above is what you need to read its output: a trend with changepoints, components
you can plot one by one, and a holiday table somebody wrote and somebody should check.

Prophet's own documentation is honest about where it is weak: it is built for business series
with strong seasons and several years of history, and on series without those it can do worse than
simple methods. The next section is about exactly that.
