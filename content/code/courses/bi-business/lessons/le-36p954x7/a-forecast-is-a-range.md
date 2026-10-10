---
title: A forecast is a range
version: 1
---

In January 2026 Otávio Lins, the CFO, asked Lívia how much Varanda would sell in the first quarter.
He needed it for the bank and for the stock orders, and he wanted one number. **The wrong idea is
that a forecast is a number. A forecast is a number, a horizon and a range**, and the range is the
part that tells the person deciding how much weight the number can carry.

## Why one number misleads

Every forecast will be wrong. The only questions are by how much, and in which direction. A single
number hides both: "R$ 22.0 million" reads as a fact, and when the quarter closes a little lower somebody
will say the forecast failed, though a miss of that size was always likely. Worse, Otávio
cannot plan for a miss nobody told him about. If the honest answer is "between R$ 21.5 and 22.5
million", he can set the stock orders for the middle and keep the bank covered for the bottom.

**A range is not an admission of weakness.** It is the information the decision needs. A forecast of
22.0 that can be off by 2% and one that can be off by 20% lead to different stock orders, and only
the range says which one you have.

## The horizon

A forecast for next week is easier than one for next December, because less can change in between.
**Every forecast states its horizon**, the distance from the last known data to the period being
forecast, and every range widens as the horizon grows. Lívia's quarter has a horizon of one to three
months from the close of 2025. The next section makes a forecast with a horizon of up to six months,
to see what that costs.

## Three methods that need nothing but history

Before anybody builds a statistical model, three simple methods set the bar. Each needs only the
sales history Varanda already has, and each fits in one spreadsheet formula:

| method | the forecast for a month is | what it assumes |
|---|---|---|
| naive | the last month you know | nothing changes from here |
| seasonal naive | the same month a year before | this year repeats last year |
| seasonal naive × growth | the same month a year before, times the recent growth | this year repeats last year's shape, at the recent pace |

**The naive method ignores the season**, and at Varanda that is fatal: a forecast that says December
will sell what June did misses December by 40%, as the next section measures. The seasonal naive method keeps the shape of the year but
assumes no growth, so in a company growing every year it is wrong in the same direction almost every month.
The third method keeps the shape and adds the pace, much as an experienced manager forecasts in
their head.

These are called **baselines**. A fancier method has to beat them to be worth its cost, and quite
often it does not. That comparison is the subject of `machine-learning` lesson 2, and the same discipline
applies here: before trusting any forecast, find out how a baseline would have done. The next
section does that for the second half of 2025, with only the data Lívia would have had at the end of
June.
