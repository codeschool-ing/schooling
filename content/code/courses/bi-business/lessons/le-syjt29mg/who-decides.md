---
title: Who decides
version: 1
---

The reorder rule and the December promotion are both prescriptive, and they end in different places.
The rule raises purchase orders by itself, many times a year. The promotion went to a meeting, once.
**The difference is not the method. It is the cost of being wrong, and whether a mistake can be
undone.**

## Automate, or recommend

Three questions place a decision on one side or the other:

| question | automate when | recommend when |
|---|---|---|
| how often is it made? | many times a week | once a year, or once |
| what does a mistake cost? | a little, and it shows up quickly | a lot, or it shows up late |
| can it be undone? | yes: the next order corrects it | no, or only at great cost |

The reorder point sits on the left of every row. Varanda places hundreds of orders a year, a reel
order that is a little early or late costs a few reels of stock or a few lost sales, and the next
order corrects it. **Leaving it to a person would mean the same arithmetic done by hand, more slowly
and less consistently.**

Closing a store sits on the right of every row. It happens once, it costs jobs, leases and customers,
and it cannot be reversed by next month's data. However good the analysis, it goes to Helena as a
recommendation with its assumptions written out. The December promotion is in between: it happens
once a year, a wrong choice costs some profit, and nothing about it is permanent. It went to a
meeting because its objective was not settled, not because the arithmetic was hard.

## The human in the loop

Between the two sits a common arrangement: the system proposes and a person approves. The reorder
rule can raise a draft order that the warehouse confirms with a click, and it can flag the orders that
look unusual, such as one three times the normal size. **A person in the loop is useful only if they
can see why the system proposed what it did.** An approval screen that shows the order and hides the
average demand and the lead time behind it trains people to click "approve" without reading.

## Somebody owns the rule

An automated decision still has an owner. The reorder point of 198 was right for a seven-day supplier
and wrong for a ten-day one, and the rule did not know that. Somebody has to:

- own each input: who tells the system that the lead time changed;
- review the rule on a calendar: Caio's team looks at every reorder point each quarter;
- watch the outcome: the days a product was out of stock, which is the number that says the rule
  failed.

**Automating a decision moves the responsibility; it does not remove it.** When the shelf is empty
in December, "the system ordered it" is not an answer, and the question that follows is who last
checked the system's inputs. Lessons 10 and 11 turn that habit into indicators with owners, which is
where the course goes next.
