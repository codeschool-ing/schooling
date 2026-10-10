---
title: When forecasts fail
version: 1
---

The backtest's one large miss came from an event the history did not contain. **Every forecast built
from the past assumes that the future works like the past**, and the places where that assumption
breaks are predictable even when the numbers are not. A BI analyst's job is to know them and to say
so beside the forecast.

## Something with no history

A method that copies last year's month needs a last year. Varanda has nothing to copy for:

- a new store, which has no October 2024 to repeat. The usual workaround is to borrow the shape of
  a similar store and scale it, which is an assumption and has to be written down as one;
- a new product line, such as an outdoor-kitchen range launched in March, whose first months
  reflect the launch, the display and the novelty, and say little about month eight;
- a new channel, where early growth rates are huge and fall quickly, so the pace of the first
  half says almost nothing about the second.

In each case the forecast is a guess dressed in a method. That does not make it useless, but its
range has to be far wider than 2.3%, and the note beside it has to say why.

## A break in the pattern

Sometimes the past stops describing the future for everybody at once. A pandemic, a flood that
closes a road, a new tax, a competitor opening across the street: after any of them, last year's
months describe a world that no longer exists. **The sign of a break is a backtest that suddenly
gets worse**: errors that were 2% become 10%, all in the same direction. When that happens the right
response is to say the method has stopped working, not to keep publishing its output with the old
range.

## A forecast that changes what it forecasts

The subtlest failure is a forecast that people act on, so that the action changes the result. Caio
Barreto, the operations director, orders stock for the garden department from the sales forecast.
Suppose the forecast for a new hose reel is low. Caio orders little, the shelves empty halfway
through the month, customers who wanted one leave without it, and the month's sales come in low.
**The forecast now looks accurate, and it caused the number it predicted.** Sales data records what
was sold, not what was wanted, so the lost sales appear nowhere. Lesson 18 comes back to stock-outs as
the sales that never show up in the data.

The defence is to check a forecast against something it could not have influenced: the days on
which the product was in stock, the visits to its page on the website, or the orders that could not
be filled.

## Who builds the richer models

Everything in this lesson fits in a spreadsheet, on purpose. A data scientist goes further: models
that use the weather, prices, promotions and the calendar together, or that forecast thousands of
products at once. `statistics` lesson 19 introduces the regression such models start from, and the
`machine-learning` course builds them. **Each of them is still judged the way this lesson judged
three formulas**: a backtest on months it did not see, its errors, its bias, and the comparison with
the baseline it has to beat. An analyst who can ask for those four things can review any forecast
handed to them, however it was made.
