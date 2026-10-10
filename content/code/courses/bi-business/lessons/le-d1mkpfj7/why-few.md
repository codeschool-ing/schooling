---
title: Why few
version: 1
---

When an analyst is asked which numbers belong on a page, the safe-looking answer is all of them:
nobody can complain that their number was left out, and a reader can ignore what they do not need.
**The second half of that is the mistake. A reader cannot ignore forty numbers selectively**; they
either read all of them shallowly or skip the page, and in both cases the four that should have
started a conversation are lost among the thirty-six that should not.

## A page is read in the time somebody has

Varanda's operations meeting is on Monday at nine, with Caio Barreto, Marcos from
deliveries, the warehouse manager, the three regional store managers, Lívia and one other: eight people. In January
2026 the page Lívia inherited for it carried forty indicators. Suppose the meeting gives each one
45 seconds, which is not long enough to discuss anything, over 48 working weeks. In a new sheet:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Indicators | Seconds each | People | Weeks |
| 2 | 40 | 45 | 8 | 48 |
| 3 | 6 | 45 | 8 | 48 |

Minutes per meeting, hours of people's time per week, and hours per year:

```localised
=A2*B2/60                        30
=A2*B2/60*C2/60                  4
=ROUND(A2*B2/60*C2/60*D2,0)      192
```

**Thirty minutes of every meeting, four hours of people's time a week, and 192 hours a year spent
reading numbers aloud**, before anybody has decided anything. The same formulas on row 3, for six
indicators:

```localised
=A3*B3/60                        4.5
=ROUND(A3*B3/60*C3/60*D3,0)      29
```

Four and a half minutes a meeting and 29 hours a year. The difference is time the meeting can spend on the one
number that moved.

## Every indicator costs something

Reading time is the visible cost. Three others are paid out of sight:

- *The data*: somebody has to extract it, check it every week, and notice when the source changes.
  At Varanda that is Tiago's pipelines and Lívia's Monday morning;
- *The definition*: lesson 10's card, written and kept true. Forty cards is a document nobody
  maintains, and an indicator whose card has drifted gives a number nobody can explain;
- *The owner's attention*: a KPI needs somebody who acts when it moves. Caio can act on a
  handful; on forty, he acts on whichever one was mentioned last.

So an indicator is not free because the system can produce it. **It earns its place if what it
changes is worth more than what it costs**, which is the value-of-information test of lesson 2
applied to a page instead of an analysis.

## How few is few

**Five to seven indicators per audience** is a working limit, not a law. It comes from practice
rather than from an experiment: it is about what fits on one screen or one printed page without
scrolling, and about how many separate things a meeting can discuss in the time it has. A board
looking at the year may need fewer; the people running a warehouse floor may need a few more, as
long as each one is something they act on today.

Two details keep the limit honest. It is **per audience**, so Helena's page and Caio's page each get
their own handful, and a number can be a KPI on one and a metric one click below on the other, as
lesson 10 showed. And the indicators that do not make the page are not deleted: they stay as metrics,
available when somebody is diagnosing a problem. **Choosing few is choosing what is read every week,
not what is kept.**

The next section is the method for choosing them, and it starts from the objective rather than from
the list of what the systems can produce.
