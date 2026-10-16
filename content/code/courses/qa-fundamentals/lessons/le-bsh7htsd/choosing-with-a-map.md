---
title: Choosing tests with a map
version: 1
---

**Grey box's other use is choosing what to test.** Knowing how a system is put together tells you where
defects are likely to travel, and which tests are worth more than the others.

## Defects travel along the arrows

`orders.py` does not compute prices. It asks `tickets.py` for each one. That single fact, the kind of thing
a box-and-arrow drawing shows, says that **every defect in `tickets.py` is also a defect in an order**,
without anybody having to find each one twice. The sixty-year-old pays full price in an order. A child on
a Wednesday is charged a quarter.

```
lia@lab:~/aurora$ python orders.py wed 20:00 35 8
order 5: 2 tickets, R$ 27,00
```

R$ 27,00 for an adult and a child at a Wednesday evening session: R$ 18,00 for the adult, which is right,
and R$ 9,00 for the child, a quarter of the full price. Lesson 6's stacking defect arrived in the order
unchanged. A grey-box tester who knows the arrow does not need to re-run every price case through
`orders.py`; they need one or two to confirm the arrow exists, and then they can say with confidence that
fixing `tickets.py` fixes both.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l08-map\" aria-label=\"A box-and-arrow map. A customer or the box office sends day, time and ages to orders.py. orders.py sends age, day and time to tickets.py and gets a price back. orders.py writes a row into the orders table in aurora.db. The nightly seats report adds up the tickets column and is read by Célia. Three questions are attached: at an arrow, same form both sides; at the store, only when it should; at the reader, same meaning.\"><defs><marker id=\"qa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">customer or box office</text><rect x=\"250.0\" y=\"40.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">orders.py</text><rect x=\"500.0\" y=\"40.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tickets.py</text><path d=\"M171.0 62.0 L249.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"210.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">day, time, ages</text><path d=\"M401.0 56.0 L499.0 56.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"450.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">age, day, time</text><path d=\"M499.0 72.0 L401.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"450.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">price</text><rect x=\"250.0\" y=\"150.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aurora.db · orders</text><path d=\"M325.0 85.0 L325.0 149.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"332.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">writes a row</text><rect x=\"500.0\" y=\"150.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nightly seats report</text><path d=\"M401.0 172.0 L499.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-amber)\"></path><text x=\"450.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">adds up tickets</text><text x=\"575.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Célia</text><text x=\"20.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 · arrow: same form both sides?</text><text x=\"20.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 · store: only when it should?</text><text x=\"20.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 · reader: same meaning?</text></svg>", "caption": "Everything a grey-box tester needs to know about the order program, and none of it is code. The defect in this lesson sat between the store and the reader."}
```

## Where the map points

Read the drawing and ask, of each box and each arrow, what could go wrong there:

- **at an arrow**, information crosses from one part to another. Does the order pass the time in the same
  form the price rule expects? A session typed as `9:30` in the order arrives at the price rule as `9:30`,
  and lesson 4 already knows what happens then;
- **at a store**, something is kept after the program ends. Is it kept only when it should be? This lesson
  found it was not;
- **at a reader**, something else depends on what was stored. Does the report read the column the way the
  order program meant it? Here it did, which is exactly why the refused rows were counted.

These three questions find the defects that live **between** parts, which neither a test of the price rule
nor a test of the order screen would reach on its own. As systems grow, more and more of their defects live
in those gaps: the code in each box works, and the boxes disagree about what they hand each other.

## The three approaches together

| | black box | grey box | white box |
|---|---|---|---|
| **knows** | the rule | the rule and the architecture | the code |
| **checks** | what the user sees | what the user sees and what was stored | what the code does, line by line |
| **found here** | the 9:30 session, the Wednesday stacking, bad inputs | refused orders stored and counted | the untested line for over-sixties, the untaken paths |
| **cannot see** | anything no rule points at | details of every line | code that is missing |

No approach found everything, and every approach found something the others missed. That is the practical
conclusion of these three lessons: **choose the approach by the question you are asking**, and expect to
use all three on any system worth testing. The next lessons step back from the tester's angle to the team's
process, starting with the oldest one, where testing came at the very end.
