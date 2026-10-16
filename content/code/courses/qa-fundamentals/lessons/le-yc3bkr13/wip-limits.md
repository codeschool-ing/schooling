---
title: Work-in-progress limits, and why less makes more come out
version: 1
---

**A work-in-progress limit is the most cards a column may hold at once.** When the column is full, nobody
may pull another card into it. It sounds like a rule for slowing down, and it is the opposite: it is the
rule that makes finished work come out faster.

## Little's law

The arithmetic behind it was proved by John Little in 1961 for any queue that is stable over time:

> **average time in the system = average work in progress ÷ average throughput**

At Cine Aurora in March, the board held 9 cards on average between "ready" and "done", and 3 cards a week
reached "done". So a card spent, on average, 9 ÷ 3 = **3 weeks** on the board. Célia asked for the child
price on the sign and saw it three weeks later, for a change that took Rafael one afternoon.

The law does not say which way to move. Finishing more per week is hard: it means working faster or with more
people. Holding fewer cards is a decision the team can take tomorrow. With the same throughput and 6 cards
instead of 9, the average falls to 6 ÷ 3 = 2 weeks. Nobody worked faster; the cards stopped waiting.

## Where the limit bites

Rafael can build faster than Lia can test, so on the old board cards piled up in "waiting for test". The team
put limits on the board:

| column | limit |
|---|---|
| ready | 4 |
| building | 2 |
| waiting for test | 2 |
| testing | 1 |

The first week, "waiting for test" filled to two and Rafael finished a card he could not move. The rule says
he may not start another. What he can do is **help the card in front of him move**: pair with Lia on the
testing, or write the automated check for the card she is exploring. The Kanban community's slogan for this is
**stop starting, start finishing**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 180\" role=\"img\" data-fig=\"l13-limits\" aria-label=\"Little’s law drawn twice. Above, nine cards on the board and three a week reaching done: each card spends three weeks on the board. Below, six cards and the same three a week: two weeks. Nobody works faster; there are fewer cards waiting.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"340.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">time on the board = cards ÷ throughput</text><rect x=\"10.0\" y=\"44.0\" width=\"400.0\" height=\"50.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"62.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"104.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"146.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"188.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"230.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"272.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"314.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"356.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">9 cards on the board</text><path d=\"M412.0 69.0 L470.0 69.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"476.0\" y=\"50.0\" width=\"90.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"521.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3 weeks</text><rect x=\"10.0\" y=\"114.0\" width=\"400.0\" height=\"50.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"62.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"104.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"146.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"188.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"230.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6 cards on the board</text><path d=\"M412.0 139.0 L470.0 139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"476.0\" y=\"120.0\" width=\"90.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"521.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2 weeks</text><text x=\"441.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 a week reach done</text></svg>", "caption": "Same people, same speed, fewer cards in progress: every card comes out sooner."}
```

## What the limit does to testing

Three things changed for Lia, and none of them was that she worked harder.

- **Cards arrived one or two at a time**, while Rafael still remembered them. A defect she found was fixed the
  same day, the cheap end of the curve from lesson 3.
- **Testing stopped being somebody else's queue.** When the column was full, testing became the whole team's
  problem, which is lesson 5's whole-team approach enforced by a number on a board.
- **The bottleneck became visible.** If the column is always full, testing is where the system is slowest,
  and that is a fact the team can act on: automate more checks, make cards smaller, or share the testing.

A limit is a policy, not a law of nature. A team picks a number, watches what happens, and moves it. A limit so
high it never bites is a decoration. One so low that people sit idle every day is too low, and the board will
show that as well.
