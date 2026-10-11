---
title: The CD3 sheet: an order, and what it costs
version: 1
---

Reinertsen's rule for a queue of work competing for the same people is to divide each item's cost
of delay by its duration and do the highest result first. He called it **CD3, cost of delay divided
by duration**. It is the same calculation as WSJF in process-management lesson 12, with money in
place of points and weeks in place of size, and that change is what lets you add up what an order
costs.

## The sheet

In your spreadsheet, as set up in lesson 1, a new sheet with the four items:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Candidate | CoD a week | Weeks | CD3 |
| 2 | Festival seat maps | 30000 | 6 | |
| 3 | Pix in instalments | 48000 | 12 | |
| 4 | Seat-hold fix | 18000 | 3 | |
| 5 | Partner API | 12000 | 4 | |

In D2:

```localised
=B2/C2      5000
```

Copied down, D3 to D5 read 4000, 6000 and 3000. Each is the cost of delay an item removes **per week of the group's time**. Finishing the seat-hold fix stops R$ 18,000 a week of delay
for 3 weeks of work, R$ 6,000 for each of those weeks. Finishing Pix stops R$ 48,000 for 12 weeks
of work, R$ 4,000 for each.

The order, highest first, without sorting anything by hand:

```localised
=INDEX(A2:A5,MATCH(LARGE(D2:D5,1),D2:D5,0))      Seat-hold fix
=INDEX(A2:A5,MATCH(LARGE(D2:D5,2),D2:D5,0))      Festival seat maps
=INDEX(A2:A5,MATCH(LARGE(D2:D5,3),D2:D5,0))      Pix in instalments
=INDEX(A2:A5,MATCH(LARGE(D2:D5,4),D2:D5,0))      Partner API
```

`LARGE(D2:D5,1)` finds the largest CD3, `MATCH` finds which row holds it, and `INDEX` returns the
name in that row. Change an estimate in column B or C and the order rewrites itself.

**The seat-hold fix comes first**, with the third-largest cost of delay, because it is short. Pix,
with the largest cost of delay, comes third, because it is long.

## What an order costs

CD3 gives an order. Money gives the next thing: **what each order costs in delay**, so that two
orders can be compared in reais. For each item, multiply its cost of delay by the week it finishes,
and add the four up. For the CD3 order:

| item | finishes in week | cost of delay a week | delay cost |
|---|---|---|---|
| Seat-hold fix | 3 | R$ 18,000 | R$ 54,000 |
| Festival seat maps | 9 | R$ 30,000 | R$ 270,000 |
| Pix in instalments | 21 | R$ 48,000 | R$ 1,008,000 |
| Partner API | 25 | R$ 12,000 | R$ 300,000 |
| **total** | | | **R$ 1,632,000** |

Do the same for the two orders the meeting proposed. Pix first, festival maps second — **highest
cost of delay first** — costs R$ 1,794,000. The quick wins first, **shortest first**, costs
R$ 1,728,000.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"l13-orders\" aria-label=\"Three rows of blocks along a time axis of 25 weeks, one row per order. By CD3: seat-hold fix, festival seat maps, Pix in instalments, partner API, delay cost R$ 1,632,000. Highest cost of delay first: Pix in instalments, festival seat maps, seat-hold fix, partner API, R$ 1,794,000. Shortest first: seat-hold fix, partner API, festival seat maps, Pix in instalments, R$ 1,728,000.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">By CD3, highest first</text><text x=\"700.0\" y=\"22.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">delay cost R$ 1,632,000</text><rect x=\"21.0\" y=\"32.0\" width=\"79.6\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"60.8\" y=\"47.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">Seat-hold</text><text x=\"60.8\" y=\"60.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">fix</text><rect x=\"102.6\" y=\"32.0\" width=\"161.2\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"183.2\" y=\"54.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Festival seat maps</text><rect x=\"265.8\" y=\"32.0\" width=\"324.4\" height=\"36.0\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"428.0\" y=\"54.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">Pix in instalments</text><rect x=\"592.2\" y=\"32.0\" width=\"106.8\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.6\" y=\"54.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Partner API</text><text x=\"20.0\" y=\"92.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Highest cost of delay first</text><text x=\"700.0\" y=\"92.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">delay cost R$ 1,794,000</text><rect x=\"21.0\" y=\"102.0\" width=\"324.4\" height=\"36.0\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"183.2\" y=\"124.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">Pix in instalments</text><rect x=\"347.4\" y=\"102.0\" width=\"161.2\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"124.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Festival seat maps</text><rect x=\"510.6\" y=\"102.0\" width=\"79.6\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"550.4\" y=\"117.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">Seat-hold</text><text x=\"550.4\" y=\"130.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">fix</text><rect x=\"592.2\" y=\"102.0\" width=\"106.8\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.6\" y=\"124.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Partner API</text><text x=\"20.0\" y=\"162.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Shortest first</text><text x=\"700.0\" y=\"162.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">delay cost R$ 1,728,000</text><rect x=\"21.0\" y=\"172.0\" width=\"79.6\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"60.8\" y=\"187.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">Seat-hold</text><text x=\"60.8\" y=\"200.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">fix</text><rect x=\"102.6\" y=\"172.0\" width=\"106.8\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Partner API</text><rect x=\"211.4\" y=\"172.0\" width=\"161.2\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"292.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Festival seat maps</text><rect x=\"374.6\" y=\"172.0\" width=\"324.4\" height=\"36.0\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"536.8\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">Pix in instalments</text><path d=\"M20 236 L700 236\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M20.0 236 L20.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"20.0\" y=\"254.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">week 0</text><path d=\"M156.0 236 L156.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"156.0\" y=\"254.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M292.0 236 L292.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"292.0\" y=\"254.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M428.0 236 L428.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"428.0\" y=\"254.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">15</text><path d=\"M564.0 236 L564.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"564.0\" y=\"254.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><path d=\"M700.0 236 L700.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"700.0\" y=\"254.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">25</text></svg>", "caption": "The same four pieces of work in three orders. Every order ends in week 25; what changes is how long each item waits, and the cost of delay it piles up while waiting."}
```

Every order finishes all four items in week 25, so the totals differ only in how long each item
waits. **The CD3 order is R$ 162,000 cheaper than Pix first**, and R$ 96,000 cheaper than shortest
first, for the same work by the same people.

## Why dividing works

Take two items next to each other in a queue and ask whether swapping them helps. Put Pix before
the seat-hold fix and the fix waits 12 more weeks: 12 × R$ 18,000 = R$ 216,000. Put the fix before
Pix and Pix waits 3 more weeks: 3 × R$ 48,000 = R$ 144,000. The fix goes first, because making Pix
wait costs less than making the fix wait. **That comparison is exactly a comparison of the two CD3
figures**, R$ 6,000 against R$ 4,000, and doing it for every neighbouring pair gives the CD3 order.

## What money adds to the points

Process-management lesson 12 produces an order from relative points, and for many queues that is
enough. Money adds three things.

**The gap between two orders has a size.** R$ 162,000 is a number Júlia can weigh against her
reasons for wanting Pix first. Points produce a ranking and say nothing about how much is lost by
ignoring it.

**It can be compared with things outside the queue.** R$ 162,000 is more than half an engineer-year
at lesson 11's R$ 264,000. A disagreement about order costs the company as much as a hire would,
and that is worth knowing before the meeting ends.

**It agrees or disagrees with the strategy, visibly.** Lesson 1's guiding policy is to protect the
on-sale first. Here the arithmetic agrees: the seat-hold fix leads on CD3 as well. When the policy
and the sheet disagree, one of them is wrong, either an estimate or the policy itself, and finding
out which is a better use of the meeting than either side insisting.

The sheet does not decide alone. Two items close in CD3 can swap on a small change in an estimate;
a fixed-date item is scheduled rather than ranked. What the sheet does is turn "mine is the
priority" into a number everybody can check, which leaves the meeting arguing about estimates
rather than about who is louder.
