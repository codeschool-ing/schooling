---
title: Three roles on two axes
version: 1
---

**Senior engineer, tech lead and architect are not three rungs of one ladder.** The usual picture
puts them in a line: a few years as a senior engineer, then leading a team, then architect, and each
step means knowing more. That picture mixes two different things. *Senior* is a level, a measure of
how far a company trusts somebody's judgement. *Tech lead* and *architect* are roles, jobs with a
scope of their own. A senior engineer may be a tech lead, an architect may never have led a team,
and the three differ less by how much they know than by **how much of the system their decisions
touch and how long those decisions have to hold**.

Those are the two axes of this lesson, **scope** and **horizon**, and each of Carreto's three
people below sits at a different point on both.

## The senior engineer: depth in one place

Paula Reis is a senior engineer on Carreto's Platform team. Her week, taken from her calendar:
moving the CI runners to a new machine image, reviewing eleven pull requests, two days on call, and
an afternoon pairing with a Matching developer who could not work out why a deploy took 22 minutes.
**Her scope is her own work and the part of the system her team owns; her horizon is the sprint,
and at the far end the quarter.**

What makes her senior is not a wider scope. It is that she is trusted to take the decisions inside
it without anybody checking them: how to cache the build, whether a test belongs in the slow suite,
when a fix is good enough to ship. Lesson 1 measured architecture by the cost of change, and these
decisions are cheap to change. That is exactly why the person closest to the code should take them,
and why a company that routes them through anybody more senior is paying for a queue.

Ícaro Nunes, two years out of university and on Payments, sits further down both axes: one task at
a time, decided within the day, with the review of a more experienced colleague behind most of
them. Seniority is the distance between Ícaro and Paula, and it is mostly trust earned on the same
kind of decision.

## The tech lead: one team's direction

Bruno Farias is the tech lead of Payments. His week: planning the next two sprints with the product
manager, cutting the Pix payout work into tickets Ícaro can pick up without getting lost, choosing
the retry library the team will standardise on, unblocking a deploy that failed on a missing
secret, and writing code for about a third of his time. **His scope is one team's delivery and its
technical direction; his horizon is the quarter, sometimes two.**

The tech lead answers a question nobody else on the team answers: *how does this team build what it
has to build?* That covers the team's internal design (how Payments divides its modules, which
tables it keeps, how it tests) and the way the team works together on the code. It does not cover
how Payments fits with Tracking or Matching, except that Bruno speaks for his team when that is
discussed.

## The architect: the joints between teams

Renata Okubo's week had four items in it:

- an hour with Bruno and the Tracking tech lead on how Payments learns that a delivery was proved,
  which lesson 5 wrote down as a decision record;
- a review of a Matching design for offering loads to drivers in batches;
- the quarterly pass over the risk register from lesson 14;
- an afternoon writing the fitness function from lesson 9 for another pair of modules.

 **Her scope
is the system across teams; her horizon is one to three years.**

Look at what is missing from that week. **She took no decision that lives entirely inside one
team.** Every item crossed a team boundary or would cost a great deal to change later, which is
lesson 6's test for an architectural decision applied to a person's calendar instead of to a
design.

## The two axes in one picture

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 392\" role=\"img\" aria-label=\"A chart with two axes. Across, scope: one task, one team&#x27;s code, one team, several teams, the company. Up, horizon: days, a sprint, a quarter, a year, years. A junior developer, Ícaro, sits at one task and days. A senior engineer, Paula on Platform, covers one task to one team&#x27;s code, from a sprint to a quarter. A tech lead, Bruno on Payments, sits at one team, around a quarter. The architect, Renata, sits at several teams, from a year to years. A dashed box for the enterprise architect of lesson 4 sits at the company and years.\"><path d=\"M100 330 L700 330\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M100 330 L100 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M96 60 L104 60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">years</text><path d=\"M96 120 L104 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a year</text><path d=\"M96 180 L104 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a quarter</text><path d=\"M96 240 L104 240\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sprint</text><path d=\"M96 300 L104 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"300\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">days</text><path d=\"M170 326 L170 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"170\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one task</text><path d=\"M290 326 L290 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"290\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one team's code</text><path d=\"M410 326 L410 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"410\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one team</text><path d=\"M530 326 L530 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"530\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">several teams</text><path d=\"M650 326 L650 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"650\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the company</text><text x=\"400\" y=\"376\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">scope: how much of the system a decision touches</text><text x=\"100\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">horizon: how long a decision has to hold</text><rect x=\"112\" y=\"276\" width=\"116\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">junior developer</text><text x=\"170\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Ícaro</text><rect x=\"150\" y=\"196\" width=\"180\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">senior engineer</text><text x=\"240\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Paula, Platform</text><rect x=\"350\" y=\"146\" width=\"120\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tech lead</text><text x=\"410\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Bruno, Payments</text><rect x=\"478\" y=\"70\" width=\"124\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">architect</text><text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Renata</text><rect x=\"614\" y=\"40\" width=\"82\" height=\"48\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"655\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">enterprise</text><text x=\"655\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">architect</text><text x=\"655\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lesson 4</text></svg>", "caption": "Each role sits where its decisions do: further right, the decision touches more teams; higher up, it has to hold for longer. The dashed corner is lesson 4's enterprise level, which Carreto, at 50 engineers, does not staff."}
```

The picture says something the job titles do not. **Moving right or up is a change of role, while
growing more senior moves a person within the same box.** Paula could become a far better engineer
over the next five years without ever leaving hers, and nobody should read that as a career that
stalled. If she takes Bruno's job one day, she has not climbed above her old work; she has swapped
it for a different scope and a longer horizon, and some of what made her good at the first will
not help with the second.

## Larson's four archetypes

Will Larson's *Staff Engineer: Leadership beyond the management track* (2021) came out of
interviews with engineers working above the senior level. One of its findings is that the same
title, *staff engineer*, covers several quite different jobs, and he describes four of them as
**archetypes**:

| archetype | what the job is, paraphrased | at Carreto |
|---|---|---|
| tech lead | guides the approach and execution of one team, usually alongside its manager | Bruno, on Payments |
| architect | answers for the direction and quality of a critical area, across teams and over time | Renata |
| solver | goes deep into one hard problem after another, wherever the company needs it | Paula, the month the monolith's database ran out of connections |
| right hand | extends an executive's reach, borrowing their scope and authority to run something complicated | nobody yet; Tomás has nobody in this role |

Two things follow for this course. First, **the archetypes are shapes of one level**: all four are
staff engineers, and what separates them is scope and horizon, which is this section's argument in
somebody else's data. Second, the architect archetype is not the only one that takes architectural
decisions. Paula, as a solver, changed how the monolith pools its database connections, and that
decision will outlive the incident by years. What the architect has that the solver does not is
**an area to answer for over time**: the solver leaves when the problem is solved, and the architect
is still there when the decision has to be revisited.

Paula's month as a solver is also a reminder that a person moves between archetypes. Companies need
different shapes at different times, and the shape someone holds this year is a fact about what
Carreto needed this year.

## Why the axes matter before the overlaps

Every disagreement about whose decision something is turns out to be a disagreement about where the
decision sits on these two axes. **A decision that touches one team and holds for a sprint belongs
to that team; one that touches several teams or holds for years needs somebody whose job is that
scope.** The next section is about the cases where the answer is not obvious, and about the table
Carreto wrote so that it would not have to argue the same case twice.
