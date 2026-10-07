---
title: Same analysis, four rooms
version: 1
---

An analysis has one truth and **as many presentations as it has audiences**. Each audience decides
something different, thinks in a different unit and has a different amount of time, and a presentation
that ignores those differences is written for nobody in particular.

## What each audience needs

| | board | management | technical team | client |
|---|---|---|---|---|
| **decides** | priorities, budget, targets | which lever, by when | whether the analysis is right | whether to change how they work with you |
| **thinks in** | money and risk | cost, people, dates | definitions and method | their contract and their reputation |
| **depth** | one level | two levels | every level | the part that concerns them |
| **time** | minutes | a slot in a meeting | as long as it takes | one meeting, maybe two |

None of these audiences is more important than the others. The board can set the target and still fail
to get the change made; management can approve the pilot and see it undermined by a technical team that
never trusted the numbers. **The analysis usually has to pass through all four**, and in an order lesson 13
discusses.

## Faro, four openings

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 360\" role=\"img\" data-fig=\"l04-openings\" aria-label=\"Four opening slides for the same finding. For the board: late first deliveries cost about R$ 793 thousand a year in margin. For management: cut late first deliveries with an eight-week pilot, with the owner and the start date. For the technical team: what late means in this analysis, with a table of definitions. For Ligeiro, the carrier: the contract promises two working days, and first orders miss it 17.3% of the time.\"><text x=\"14.0\" y=\"14.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">board</text><rect x=\"14.0\" y=\"24.0\" width=\"316.0\" height=\"150.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"28.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Late first deliveries cost us</text><text x=\"28.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">about R$ 793 thousand a year</text><text x=\"172.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--amber)\">R$ 793 thousand</text><text x=\"172.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">customer margin lost each year</text><text x=\"350.0\" y=\"14.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">management</text><rect x=\"350.0\" y=\"24.0\" width=\"316.0\" height=\"150.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"364.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Cut late first deliveries with</text><text x=\"364.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">an 8-week pilot from 1 Sept</text><text x=\"364.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lever: remove the address check</text><text x=\"364.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">owner: Sandra’s team</text><text x=\"364.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">goal: 17.3% late → 8%</text><text x=\"364.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">start: 1 September</text><text x=\"14.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">technical team</text><rect x=\"14.0\" y=\"196.0\" width=\"316.0\" height=\"150.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"28.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">What late means in this</text><text x=\"28.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">analysis, and how it is counted</text><text x=\"28.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">late</text><text x=\"148.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">after the checkout date</text><text x=\"28.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">first_delivery</text><text x=\"148.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">first box of the subscription</text><text x=\"28.0\" y=\"306.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">cancelled_90d</text><text x=\"148.0\" y=\"306.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">within 90 days of it</text><text x=\"350.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">client: Ligeiro</text><rect x=\"350.0\" y=\"196.0\" width=\"316.0\" height=\"150.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"364.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Our contract promises two</text><text x=\"364.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">working days; first orders miss it</text><text x=\"446.0\" y=\"272.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">renewals</text><path d=\"M454.0 264.0 L602.4 264.0 L602.4 280.0 L454.0 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"606.4\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">95.1%</text><text x=\"446.0\" y=\"302.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">first orders</text><path d=\"M454.0 294.0 L583.0 294.0 L583.0 310.0 L454.0 310.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"587.0\" y=\"302.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">82.7%</text></svg>", "caption": "Same finding, four first slides. Each opens with what that room decides and the unit it thinks in; none would work in another room."}
```

The four slides carry the same finding. The board's version leads with money, Paulo's with the choice in
front of him, the technical version with the definition of *late*, and Ligeiro's with the shared goal
of their contract. **Not one of them is dishonest**, and none would work in another room.

## How to find out what a room needs

Ask, before the meeting, three questions of somebody who will be in it:

1. *What will this group decide, or be asked to decide?* If nothing, the presentation is information,
   and it should probably be an email.
2. *What does this group already believe about the subject?* That is your context, or the conflict.
3. *What would make them stop listening?* For a board, a table. For a technical team, an undefined term.
   For a client, a hint that they are being blamed.

The rest of this lesson takes each room in turn. You will meet the same tools in all four: the
inverted pyramid from lesson 3 and the four parts from lesson 2. What changes is what goes in them.

For your own analysis, answer the three questions for two of the four rooms, and write the opening
sentence each would get in `my-analysis.txt`. If you cannot name a room that will decide anything, that
is the first thing to fix.
