---
title: Why yes is the expensive answer
version: 1
---

**Every yes spends capacity that was already promised to something else, so a yes is also a no,
said silently to whoever loses.** The person asking sees only the yes. The people whose work slips
find out later, usually without being told why, and the one who said yes is not the one who
explains it to them.

On Tuesday 10 November, Otávio, Marola's CEO, stops by the checkout team's area. A competitor has
announced "flash deals" for Black Friday, on 27 November: products at a deep discount for one hour,
with a countdown on the home screen and stock reserved for whoever puts the item in the basket
first. "Can we have that by Black Friday?" Everybody looks at Bruna, and Bruna looks at Lívia.

## The arithmetic nobody does in the corridor

Bruna's team has five engineers. From 10 November to the eve of Black Friday there are twelve
working days each, once the national holiday on 20 November is taken out: **60 engineer-days**. Already committed for those days, before Otávio arrived:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A horizontal bar of engineer-days. Already committed: load test 20, payments 8, substitution flow 15, on-call 12, making 55. A vertical line marks the capacity of 60 engineer-days. A dashed segment of 30 for flash deals, if the answer is yes, takes the total to 85, well past the line.\"><defs><marker id=\"capacity-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"60\" width=\"137\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"98.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">20</text><text x=\"32\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">load test</text><rect x=\"170\" y=\"60\" width=\"53\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"196.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><text x=\"172\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">payments</text><rect x=\"226\" y=\"60\" width=\"102\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"277.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15</text><text x=\"228\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">substitution</text><rect x=\"331\" y=\"60\" width=\"81\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"371.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"333\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on-call</text><rect x=\"415\" y=\"60\" width=\"207\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"518.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">30</text><text x=\"419\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">flash deals, if yes</text><path d=\"M450 30 L450 57\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><path d=\"M450 140 L450 160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"450\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">capacity: 60 engineer-days</text><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">already committed: 55</text><text x=\"625\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">85</text><text x=\"30\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">engineer-days of the checkout team, 10 November to Black Friday</text></svg>", "caption": "The yes in the corridor, drawn. What Otávio sees is the dashed block; what slips is everything to its left, in the busiest month of the year."}
```

- the Black Friday load test and the fixes it turns up (every year it has found something), about 20 engineer-days;
- the payment provider's mandatory update, due by 30 November, about 8;
- the substitution flow's last stage, promised to the stores for December, about 15;
- on-call, support questions and the ordinary interruptions of a team in its busiest month, about 12.

That is 55 of the 60 before anything new.

Lívia's estimate for the full flash-deal feature, with stock reservation, is **about 30
engineer-days**, and the reservation logic is the kind of change that most needs testing under load,
which is exactly what there is least time for. A yes in the corridor puts the team at 85 days of work in 60, well over its
capacity in the month when an incident costs the most.

## Why people say yes anyway

- **No feels like a refusal of the person**, especially the CEO, and yes feels like loyalty.
- **The cost of yes arrives later**, in a slipped date somewhere else; the cost of no arrives now,
  in an awkward silence.
- **Yes is easy to say vaguely** ("we'll do our best"), while a no has to be explained.

The third reason is the dangerous one. **A vague yes is the worst answer of all**: the asker
plans around it, the team cannot deliver it, and the disappointment arrives on the day it matters
most, when nothing can be done. A clear no on 10 November leaves seventeen days to do something
else; a "we'll try" that fails on 26 November leaves none.

## The job is not to say no

None of this is an argument for refusing. Otávio's request is reasonable: a competitor has a
feature, Black Friday is the biggest day of the year, and the CEO wants Marola to compete. **The
job is to make the trade-off visible, so the person with the authority to choose is choosing
between real options**, not between a yes that cannot be kept and a no that sounds like
obstruction. The rest of this lesson is how.
