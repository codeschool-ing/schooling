---
title: Hidden denominators
version: 1
---

"Complaints up 40%" is a sentence that gets a meeting's attention, and it is the sentence Varanda's
customer-service report opened with in December 2025, comparing November with the November before.
Before anybody acts on it, one question has to be asked: **40% more complaints out of how many
chances to complain?** A count with no denominator says how much of something there is, not how
often it happens, and the two can move in opposite directions.

## One table, three answers

The online shop's November in each year, with the orders, the customers who placed them, and the
complaints. Type it into a new sheet from A1:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Month | Orders | Customers | Complaints |
| 2 | Nov 2024 | 5000 | 4000 | 150 |
| 3 | Nov 2025 | 8000 | 4400 | 210 |

First, how much each column grew:

```localised
=ROUND((B3/B2-1)*100,1)      60
=ROUND((C3/C2-1)*100,1)      10
=ROUND((D3/D2-1)*100,1)      40
```

Complaints rose 40%, but orders rose 60%. **Complaints per order fell**:

```localised
=ROUND(D2/B2*100,1)      3
=ROUND(D3/B3*100,1)      2.6
```

From 3.0 complaints per hundred orders to 2.6. On that reading the operation got better: each order
was less likely to go wrong. Now the same complaints per customer:

```localised
=ROUND(D2/C2*100,1)      3.8
=ROUND(D3/C3*100,1)      4.8
```

From 3.8 per hundred customers to 4.8. **On that reading things got worse.** The same three columns
of the same two months give "complaints up 40%", "complaint rate down" and "complaint rate up", and
all three are correct arithmetic.

## Which denominator, then

The two rates disagree because customers placed more orders each in November 2025: 1.82 against
1.25 the year before, after a Black Friday campaign that brought them back several times. More orders
per customer means more chances for each customer to have something go wrong.

```localised
=ROUND(B2/C2,2)      1.25
=ROUND(B3/C3,2)      1.82
```

**The right denominator is the one that counts the chances for the thing you are asking about.** If
the question is whether the warehouse and the carriers handle an order well, every order is a chance
to fail, and complaints per order is the measure: it improved. If the question is how many people
had a bad experience with Varanda this November, every customer is a chance, and that got worse,
partly because each of them gave the shop more chances. Both belong in the report, each with its
denominator in its name. What does not belong is the bare count, "complaints up 40%", which answers
neither question.

## A rate that rose because its denominator fell

The trap also runs the other way. In one month of 2025 Renata's team paused its paid campaigns, and
online conversion jumped:

| | A | B | C |
|---|---|---|---|
| 1 | | Visits | Orders |
| 2 | Before | 300000 | 3750 |
| 3 | After | 210000 | 3375 |

```localised
=ROUND(C2/B2*100,2)          1.25
=ROUND(C3/B3*100,2)          1.61
=ROUND((C3/C2-1)*100,1)      -10
```

Conversion went from 1.25% to 1.61%, the best month the shop had recorded, and orders fell 10%.
The paid campaigns had been bringing visitors who rarely bought; when they stopped, visits fell 30%,
the remaining visitors were the keen ones, and the rate rose. **A rate can improve because its
denominator lost its worst cases**, which is good news about the rate and not about the business.
Lesson 10's tree is the check: a branch is only good news if the others held still.

## The habit

Whenever a report shows a change, ask for the denominator and look at it as well. Three questions
cover most cases: **out of how many?** (a count needs its base); **did the base change?** (a rate
can move because the bottom moved); **is the base the right set of chances?** (orders or
customers, visits or visitors). The numbers are rarely wrong. What is missing is the line underneath
them.
