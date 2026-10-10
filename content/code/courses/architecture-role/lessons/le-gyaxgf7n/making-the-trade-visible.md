---
title: Three options, and who chooses
version: 1
---

Architects fall into one of two habits when quality, time and cost pull apart. One is to decide how
good the engineering must be and defend that against the business. The other is to accept whatever
date arrives and absorb the difference quietly. **The business decides the trade between quality,
time and cost. The architect makes the consequences of each choice explicit enough for that decision
to be an informed one, and writes down what was agreed.** Neither habit does either half.

## Why three options

One option is a request for approval: the decider can say yes or no, and learns nothing about what
else was possible. Two options invite "split the difference", which is often worse than either.
**Three options, one of them the cheapest that is acceptable, give the decider a real choice and
show that the architect looked.** Lesson 14 adds "do nothing" to the comparison as a fourth
alternative worth pricing. For the CT-e layout doing nothing was not available, because after the
date every old-layout CT-e is refused, and saying so plainly was part of the presentation.

## Carreto's three

The scope for the date was settled in the previous section. What remained open was how to build it,
and in particular whether to restructure the CT-e generator first. Carreto's finance team plans with
a loaded cost of R$ 6,500 per engineer-week, a figure this lesson uses and no other. Renata and Bruno
worked out three options.

| | A: patch the generator | B: rebuild with versioned layouts | C: patch now, rebuild next quarter |
|---|---|---|---|
| work before the date | 12 engineer-weeks: 3 people, 4 weeks | 27 engineer-weeks: 3 people, 9 weeks | 12 engineer-weeks: 3 people, 4 weeks |
| work afterwards | none planned | none | 15 engineer-weeks next quarter |
| cost | R$ 78,000 | R$ 175,500 | R$ 78,000 now and R$ 97,500 next quarter |
| margin before the date | 6 weeks | 1 week | 6 weeks |
| main risk | none on the day; every later layout change costs about twice as much | new code reaches production one week before a date nobody can move | none on the day; one quarter of carrying the patch |
| what it leaves | two layouts' worth of conditionals in one generator | a generator where a new layout is a new mapping | the same as B, a quarter later |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"A timeline of weeks with a dashed line at the regulatory date, week 10, and the start of the next quarter after it. Option A, patch: a bar from week 0 to week 4, leaving 6 weeks of margin. Option B, rebuild first: a bar from week 0 to week 9, leaving 1 week. Option C, patch, rebuild later: a bar from week 0 to week 4, leaving 6 weeks of margin, and a dashed bar for the restructuring early in the next quarter.\"><defs><marker id=\"options-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">today</text><text x=\"380\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the date, week 10</text><text x=\"446\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">next quarter</text><path d=\"M380 34 L380 220\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></path><path d=\"M440 56 L440 220\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><text x=\"14\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">A  patch</text><rect x=\"180\" y=\"70\" width=\"80\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><path d=\"M264 82 L376 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"320.0\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">6 weeks of margin</text><text x=\"14\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">B  rebuild first</text><rect x=\"180\" y=\"122\" width=\"180\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"388\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1 week</text><text x=\"14\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">C  patch, rebuild later</text><rect x=\"180\" y=\"174\" width=\"80\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><path d=\"M264 186 L376 186\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"320.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">6 weeks of margin</text><rect x=\"442\" y=\"174\" width=\"100\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"550\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">restructuring</text></svg>", "caption": "The same three options against the calendar. B and C cost the same in total; what differs is where the risky work sits relative to the one date that cannot move."}
```

**C costs exactly what B costs, R$ 175,500 in total.** It does not buy a saving. It buys time: the
risky restructuring moves away from the one date that cannot slip, and in exchange Carreto carries
a patched generator for a quarter. That is the kind of trade a table like this exists to show,
because "B is the proper solution" and "C is the safe one" are both true and neither says what the
choice costs.

## Presenting it

Renata took the table to Tomás Viana, Helena Prado and Sílvio Matos in a thirty-minute meeting. She
was not there to win B, which the engineers preferred. Her one-page note said five things in order:
the date and why it cannot move; the scope handled by hand for a few weeks; the three options; her
recommendation, C, with its reason; and **what each option took from Helena's roadmap**, which is
nine weeks of the three CT-e engineers for B and four weeks for A or C. That last line was the one
Helena needed, because the same three people were due to start the return-loads work.

Sílvio asked the right question: would the fifteen engineer-weeks really happen next quarter, or be
eaten by the next feature? Renata's answer was a condition. "It goes on the roadmap now, with an
owner and a date, or I recommend B." They chose C, with the restructuring written into Payments'
plan for the next quarter.

**The architect recommends, with reasons; the people who own the time and the money decide.** Making
the consequences explicit meant putting each option in the deciders' terms: weeks of roadmap, reais,
and the chance of a truck not leaving. The craft of that conversation is taught elsewhere, in lesson
4 of `architect-communication` on translating technical risk into business risk and in its lesson 13
on negotiating deadline, scope, quality and debt.

## Writing the debt down

Option C is deliberate, prudent debt, and it stays prudent only if it is recorded. Renata wrote an
ADR for the decision (lesson 5) and added an entry to Carreto's debt register:

> **What we borrowed:** the new CT-e layout is supported by adding conditionals to the existing
> generator, not by a versioned mapping.
>
> **Why:** a regulatory date ten weeks away; restructuring first left one week of margin.
>
> **Interest:** until repaid, any change to CT-e generation takes about twice as long. A second
> layout change before repayment would take about six weeks instead of three.
>
> **Repayment:** extract a versioned layout mapping, 15 engineer-weeks, owner Bruno Farias, in the
> next quarter's plan.
>
> **Revisit if:** the tax authority announces another layout version before repayment. Then repay
> first.

The entry gives the debt an owner, a cost and a date, which is what separates a deliberate loan from
a mess. The "revisit if" line matters as much as the rest: it names the event that would make the
interest jump, so nobody has to remember the reasoning to act on it. Pricing debt properly, as
interest paid sprint by sprint, is lesson 5 of `tech-strategy`.

The new layout went live with five weeks to spare, one less than planned, and the restructuring
shipped in the sixth week of the following quarter. **Every number in this section is a single
point**, 4 weeks, 9 weeks, 15 engineer-weeks, and real estimates are not points. Lesson 14 turns
them into ranges and shows what that changes about the margin in the table above.
