---
title: Little's law, in a team's words
version: 1
---

The commonest belief about a busy team is that **starting more work gets more work done**. If five items are moving slowly, start a sixth, and at least something new is under way. Little's law says why this is wrong, and it says it with arithmetic rather than with opinion.

John Little published the proof in 1961, about queues of any kind: customers in a bank, jobs in a factory, packets in a router. Its usual form is three letters, **L = λW**. **L** is the average number of things inside the system, **λ** (lambda) is the average rate at which they leave, and **W** is the average time each one spends inside. Put into the words of a team with a board, it becomes:

```localised
average work in progress = throughput × average cycle time
```

and, rearranged, the form a tech lead uses most:

```localised
average cycle time = average work in progress ÷ throughput
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 250\" role=\"img\" data-fig=\"l01-box\" aria-label=\"A box standing for the team, with six cards inside it. Cards arrive from the left, and finished cards leave on the right. The number of cards inside is the work in progress, L; the rate at which they leave is the throughput, lambda; the time each card spends inside, from entering to leaving, is the cycle time, W.\"><defs><marker id=\"dm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190.0\" y=\"40.0\" width=\"300.0\" height=\"130.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"340.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the team</text><rect x=\"214.0\" y=\"78.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"306.0\" y=\"78.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"78.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"214.0\" y=\"120.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"306.0\" y=\"120.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"120.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"24.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"68.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"112.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M160.0 118.0 L186.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dm-ah-paper-dim)\"></path><path d=\"M494.0 118.0 L520.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dm-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"574.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"618.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">requests arrive</text><text x=\"596.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">items finish</text><path d=\"M190.0 196.0 L490.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dm-ah-amber)\"></path><path d=\"M190.0 188.0 L190.0 204.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"340.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">W: the days each item spends inside (cycle time)</text><text x=\"340.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">L: the items inside at any moment (work in progress)</text><text x=\"596.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">λ: items leaving per day</text><text x=\"596.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">(throughput)</text><text x=\"340.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">L = λ × W</text></svg>", "caption": "Any system that work enters and leaves. Know two of the three numbers and the law gives the third."}
```

## A worked example

A team finishes **five items a week** and has, on an ordinary day, **fifteen items** started and not finished. Then an item takes, on average, 15 ÷ 5 = **three weeks** from start to finish. Nobody had to time a single item to know it.

Now the team starts more. It keeps twenty items open, and because the same people are doing the same work, it still finishes about five a week. The law gives 20 ÷ 5 = **four weeks**. Every item now takes a week longer, and the extra five items did not make anything arrive sooner. That is the whole case for limiting work in progress, which lesson 4 makes in practice: **with throughput fixed, more open work only means older work**.

The opposite move is the useful one. Keep ten items open and the same five a week gives two weeks per item. The team did not get faster; each item spent less time waiting for somebody to come back to it.

## What the law needs

Little's law is a theorem, not a rule of thumb, but it is a theorem about **averages over a period in which the system is stable**. On a team's board, that means four things hold over the period you measure:

- **what starts, finishes.** An item abandoned halfway, or deleted from the board, leaves the books unbalanced;
- **arrivals and departures roughly match.** If the team starts far more than it finishes, work in progress keeps rising and no average describes it;
- **work in progress is about the same at both ends of the period.** A period that starts with an empty board and ends with a full one is measuring a ramp, not a system;
- **the units agree.** Throughput per day goes with cycle time in days, and both count the same calendar: if work in progress is counted on Saturdays, cycle time counts Saturdays too.

When those hold, the two sides agree, and you can use the law to get the number you do not have from the two you do. When they do not, the two sides disagree, and **the disagreement is itself information**: it says the system changed during the period. This lesson's last section measures both cases on the Billing team's board.

## What the law does not say

It does not say that cutting work in progress always shortens cycle time. If cutting it also cuts throughput, because people now sit idle waiting for something to start, the ratio can stay the same. In practice throughput barely moves when a team with too much open work cuts it, because the work was waiting rather than being done. Lesson 4 shows that for the Billing team, and lesson 12 shows the other end: a team so lightly loaded that removing more work would only remove output.

It also does not say anything about one item. An average cycle time of two weeks is compatible with an item that took two months. Lesson 2 is about the spread around the average, which is where the item that took two months lives.
