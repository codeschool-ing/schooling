---
title: What kind of conflict this is
version: 1
---

**A technical disagreement is usually three conflicts tangled together: about the work, about how
the decision is made, and about the people.** Mediating it starts by separating them, because each
one is resolved differently, and the one people talk about is rarely the one doing the damage.

On 1 May, the connections RFC from lesson 2 came into force: every service got a fixed quota of
connections to the orders database. Three weeks later Bruna, tech lead of checkout, wrote in the
platform channel that logistics' quota of 40 was "absurd" and should be cut to 20. Paulo, the senior
engineer on logistics, replied within a minute that checkout "breaks everything on Fridays and
then blames everybody else". By lunchtime the thread had sixty messages, and both tech leads had
messaged Lívia privately.

## Three conflicts in one thread

The organisational psychologist Karen Jehn, studying work teams in the 1990s, separated three kinds
of conflict, and the distinction is still the most useful first step:

| kind | about | in the thread |
|---|---|---|
| **task** | what the right answer is | is 40 connections too many for logistics? |
| **process** | how the decision is made, and who makes it | who decides quotas, and can they change after an RFC? |
| **relationship** | the people | "checkout breaks everything and blames everybody else" |

Early research suggested that task conflict was healthy, a sign of people caring about the work,
while relationship conflict did harm. Later work, including a much-cited review by Carsten De Dreu
and Laurie Weingart in 2003, found the picture less comfortable: task conflict also tends to hurt
team performance, especially when it starts to feel personal, which in practice it usually does.
**The practical reading is that a task disagreement has to be resolved quickly and on its merits,
before it turns into the other two.**

## How people respond to conflict

Kenneth Thomas and Ralph Kilmann described five ways people respond to a conflict, set on two
axes: how much they pursue their own concerns, and how much they pursue the other side's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Five conflict modes on two axes: pursuing your own concerns, vertical, and pursuing the other side&#x27;s, horizontal. High on your own and low on theirs: competing, I win, you lose. High on both: collaborating, find what serves both. In the middle: compromising, split the difference. Low on both: avoiding, leave it for later. Low on yours and high on theirs: accommodating, let them have it.\"><defs><marker id=\"tkmodes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M120 270 L680 270\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#tkmodes-ah)\"></path><path d=\"M120 270 L120 20\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#tkmodes-ah)\"></path><text x=\"400.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pursuing the other side's concerns →</text><text x=\"14\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pursuing</text><text x=\"14\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">your own</text><text x=\"14\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">concerns ↑</text><rect x=\"140\" y=\"30\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">competing</text><text x=\"230\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">I win, you lose</text><rect x=\"480\" y=\"30\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">collaborating</text><text x=\"570\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">find what serves both</text><rect x=\"310.0\" y=\"115\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">compromising</text><text x=\"400.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">split the difference</text><rect x=\"140\" y=\"200\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">avoiding</text><text x=\"230\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">leave it for later</text><rect x=\"480\" y=\"200\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">accommodating</text><text x=\"570\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">let them have it</text></svg>", "caption": "Thomas and Kilmann's five modes. Each is right somewhere; the trouble is a habit of one. Bruna and Paulo were both in the top-left corner."}
```

None of the five is wrong in itself. Avoiding is right for a disagreement that does not matter;
accommodating is right when the other side cares much more than you do. **What goes wrong is using
one mode for everything**, and in engineering teams the two most common habits are competing
(argue until the other side gives up) and avoiding (let the thread die and do it your own way).
Bruna and Paulo were both competing. The thread would have ended with whoever had more stamina, and
the quota would have been decided by that.

## The mediator's first move

Lívia did not reply in the channel. She asked both tech leads, Bruna and Henrique, for thirty
minutes together the next morning, and wrote one line in the thread: "Moving this to a call with
both leads tomorrow at 10:00; I'll post the outcome here." **A public thread is the worst place to
resolve a conflict**: everybody is performing for the audience, and nobody can change position
without losing face in front of it.

::: track tech-lead
`people-leadership` lesson 22, earlier in your track, covers conflict as a manager meets it:
between people you lead, and with product. This lesson is the architect's version: a disagreement
about a technical decision, between teams neither side manages.
:::

::: track *
The same skills apply to conflict inside a team you lead; this lesson takes the architect's case,
a disagreement about a technical decision between teams that neither side manages.
:::
