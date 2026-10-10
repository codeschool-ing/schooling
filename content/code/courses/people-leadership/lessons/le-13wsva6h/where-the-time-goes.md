---
title: Where the time goes, and how late the answers arrive
version: 1
---

Two things change about time when you start managing, and they pull in opposite directions. **Your
day gets cut into small pieces, and the results of what you do get further away.** An engineer
works in long blocks and finds out quickly whether the work was right. A manager works in short
blocks and finds out slowly.

## A calendar in thirty-minute pieces

Paul Graham described the first half in an essay called *Maker's Schedule, Manager's Schedule*
(2009). A maker needs units of half a day at least, because a problem worth solving takes an hour
just to load into your head. A manager's day is cut into hours or half-hours, and each slot is a
different conversation. Neither schedule is wrong. The damage comes from one person living on
both, or from a manager scheduling a maker as if they were another manager.

Renata's calendar in her third week shows it. She had four one-to-ones, a planning meeting, a
review of an incident from the weekend, an interview and two conversations with Payments. Between
them sat gaps of twenty and forty minutes: too short to load a problem, long enough to feel guilty
about wasting.

Two habits help, and both are about protecting somebody's long blocks:

- **Group your own meetings.** Renata moved her one-to-ones to Tuesday and Thursday afternoons, so
  that two mornings a week were unbroken. She uses them for the writing this job is full of:
  promotion cases, hiring rubrics, plans.
- **Protect the team's blocks more than yours.** A meeting with seven engineers at 11:00 cuts seven
  mornings in half. The team agreed that its regular meetings sit at the start of the day or after
  lunch, and nowhere in between.

## How long until you find out

The second half is harder to see because it does not show on a calendar. Every piece of work has a
loop: you act, the world answers, you learn whether you were right. **The shorter the loop, the
faster you get good at something.** Engineering is a craft of short loops. Management is a craft of
long ones.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-loops\" aria-label=\"A logarithmic time axis from one second to one year, with six loops placed on it. A test run answers in about ten seconds and a code review in about four hours: the engineer’s loops, on the left. A deploy shows how users react in about two days. A piece of feedback shows whether behaviour changed in about three weeks. A hire shows whether it was right in about six months, and a promotion case is decided at the next cycle, also about six months away: the manager’s loops, on the right.\"><path d=\"M60.0 200.0 L680.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60.0 195.0 L60.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 second</text><path d=\"M207.0 195.0 L207.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"207.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 minute</text><path d=\"M354.0 195.0 L354.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"354.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 hour</text><path d=\"M468.2 195.0 L468.2 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"468.2\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 day</text><path d=\"M538.0 195.0 L538.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"538.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 week</text><path d=\"M590.3 195.0 L590.3 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"590.3\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 month</text><path d=\"M680.0 195.0 L680.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 year</text><path d=\"M142.7 192.0 L142.7 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"142.7\" cy=\"200.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"142.7\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a test run</text><path d=\"M403.8 192.0 L403.8 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"403.8\" cy=\"200.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"403.8\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a code review</text><path d=\"M493.0 192.0 L493.0 94.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"493.0\" cy=\"200.0\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"493.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a deploy, as</text><path d=\"M577.5 192.0 L577.5 115.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"577.5\" cy=\"200.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"577.5\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">feedback</text><path d=\"M655.0 192.0 L655.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"655.0\" cy=\"200.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"655.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a hire</text><text x=\"655.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a promotion case</text><text x=\"493.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">users react</text><rect x=\"60.0\" y=\"252.0\" width=\"408.2\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"264.1\" y=\"265.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">where an engineer learns</text><rect x=\"538.0\" y=\"252.0\" width=\"142.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"609.0\" y=\"265.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">where a manager learns</text><text x=\"60.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">how long until the world tells you whether you were right</text></svg>", "caption": "Orders of magnitude, not measurements. The loops a manager learns from are slower than an engineer’s by a factor of about a million."}
```

A failing test answers in seconds. A code review answers the same day. Feedback you gave in a
one-to-one shows whether it worked over the following weeks, when the behaviour changes or does
not. A hire shows whether it was right somewhere between three months and a year. A promotion case
you write today is decided at the next review cycle, which at Caju is twice a year.

The figure's numbers are orders of magnitude, not measurements, and they are enough to make the
point. **The distance between the fastest loop on the left and the slowest on the right is about
six orders of magnitude.** No intuition trained on the left half transfers cleanly to the right.

## What long loops do to a beginner

Long loops have three effects worth naming, because each one leads to a mistake the course comes
back to.

**You cannot tell luck from skill for a long time.** A team that ships a good quarter under a new
manager may be shipping on momentum the previous manager built. A team that ships a bad one may be
paying for decisions made before she arrived. Renata will not know for months whether her changes
helped. Judging herself by the first month would be judging the weather.

**You need written records to learn at all.** If the answer arrives in six months, you will not
remember the question. The last section of this lesson sets up the notebook that fixes that, and
lessons 5 and 7 depend on it.

**You are tempted to act where loops are short.** Fixing a bug answers today, and talking to Marcos
about why his estimates keep slipping answers in a month, if at all. The bug wins every time unless
you notice the pull. That is the same failure as the ticket in the previous section, seen from the
other side.

## A week worth copying

There is no correct calendar, but there is a correct question: **which of these hours changes what
the team produces?** Renata now ends each Friday by marking her week in three colours: time that
multiplied somebody else's work, time spent on work only she can do, and time that did neither.
The third colour is never empty, and it was the largest in her first month. Watching it shrink is
the only fast loop the job gives her.
