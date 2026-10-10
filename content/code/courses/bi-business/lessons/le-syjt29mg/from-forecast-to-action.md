---
title: From a forecast to an action
version: 1
---

Lesson 8 ended with a forecast and a range. A forecast changes nothing by itself: somebody still has
to decide how many hose reels to order, whether to cut the price of a garden set, which store to
enlarge. **Prescriptive analysis is the part of BI that recommends what to do**, and it is the
easiest to get wrong in a way nobody notices, because the option that was not chosen leaves no
numbers behind to compare with.

## The shape of a prescriptive question

The wrong idea is that prescriptive analysis is a better forecast, or a smarter algorithm. It is a
different question with three parts, and none of them is a forecast:

| part | what it asks | for the hose reel at Varanda's warehouse |
|---|---|---|
| options | what could we do? | order now or later; order more or fewer |
| constraints | what limits the choice? | the supplier takes seven days; the warehouse holds about a thousand reels; the supplier sells in boxes of 30 |
| objective | what are we trying to achieve, and at what cost? | never run out, while keeping as little money in stock as possible |

**The forecast is an input, the objective is a choice.** Two people with the same forecast and
different objectives will make different recommendations, and both can be right. "Never run out" and
"hold as little stock as possible" pull against each other, and somebody has to say how much of one
is worth how much of the other. That is a business decision, and an analyst who makes it silently
inside a formula has taken a decision that was not theirs.

## From a rule to optimisation

Prescriptive work comes in sizes, and most of a BI analyst's comes in the smallest:

- a rule: "reorder when the stock reaches this level", worked out once and written down. The next
  section builds one in a sheet;
- a comparison of a few options: three possible discounts for December, each with its estimated sales
  and profit, set side by side for somebody to choose. The section after that does this one;
- optimisation software: a solver that searches thousands of combinations at once, such as how much
  of 4,000 products to send to nine stores under the limits of the trucks. That is the work of
  operations research and of data scientists, and it rests on the same three parts.

**The size does not change the shape.** A solver given the wrong objective finds the best answer to
the wrong question, faster and with more decimal places than a person would.

## Recommend, or automate

The last question is who acts on the answer. Some answers go straight into a system: the reorder rule
can raise a purchase order with nobody looking. Others go into a meeting: the December discount is a
recommendation that Renata and Helena will argue over. **What decides which is the cost of being
wrong, not the cleverness of the method**, and the last section of this lesson is about where that
line sits.
