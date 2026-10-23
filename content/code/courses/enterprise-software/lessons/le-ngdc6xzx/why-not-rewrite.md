---
title: Why not simply rewrite it
version: 1
---

Coleta has to go. It has run Serra Alta's milk collection since 1996, on IBM i, in RPG, and
most of it was written by one person. Sebastião Lima retires in 2028, and the rules that decide
what 1,900 farms are paid each month live in his code and in his head. Nobody disputes that a
replacement is needed. The argument is about how to get there.

The plan most people reach for first is the one Joana brought with her from the fintech: **write
the new system from scratch, beside the old one, and switch over on a chosen weekend.** It sounds
like the safe plan because it looks like a copy. The old system is the specification, it has
worked for thirty years, and all the new one has to do is the same thing in a modern language.

That plan has a name, the big-bang rewrite, and it has a long record of running late, running
over and sometimes never arriving at all. Not because the people doing it are careless. It fails
for three reasons that are built into its shape, and all three are present at Serra Alta.

## The target moves while you are copying it

**A rewrite copies a system that does not stand still while it is being copied.** Coleta is not
frozen. In the last twelve months Sebastião made 23 changes to it: a new bonus table for protein
agreed with the farmers' associations, a change to how a farm suspended for quality is paid when
it returns, a new field the laboratory started sending, and twenty smaller ones. None of them was
optional. The business asked, and the system that pays the farms had to follow.

During a rewrite each of those changes has to be made twice: once in Coleta, because it is the
system paying the farms today, and once in the new system, because otherwise it will be wrong on
the day it takes over. In practice the second copy falls behind. The team building the new system
is busy building it, the change log is long, and the gap between the two only becomes visible at
the end, when somebody compares them. A rewrite planned for two years against a system that
changes twice a month is a rewrite of a target nobody has seen.

## The specification is the code

The second reason is that the documents describe what somebody intended in 1996, and the code
describes what happens. **In a system this old, the program is the only complete statement of
the rules.** Coleta has a manual, written in 2003 and last updated in 2011. It covers the main
payment formula and none of the exceptions: the farms on a community tank, the way a collection
after midnight is dated, the cooperative whose farms get a winter bonus because of an agreement
signed before anybody now working at Serra Alta arrived.

Every one of those exceptions is a line of RPG that was once a phone call. Joel Spolsky made the
general point in 2000, in an essay called *Things You Should Never Do, Part I*, about Netscape's
decision to rewrite its browser from scratch. Old code is ugly partly because it has been fixed,
he wrote, and each fix is knowledge about the real world that the rewrite throws away and has to discover
again, usually in production. Fred Brooks had already described the other half in *The Mythical
Man-Month* (1975): the second system a team builds is the one where it tries to include everything
it left out of the first, which makes the copy bigger than the original.

## One date carries all the risk

The third reason is the one that makes rewrites dangerous rather than merely slow. **In a big
bang, nothing is proved until the cutover, and the cutover proves everything at once.** Two years
of work reach real farms on one day. For Coleta that day is the 10th of a month, when 1,900 farms
expect money in their accounts. If the new calculation is wrong for some of them, the first sign is
a farmer phoning the plant, and the way back is not a redeploy. Payments already made have to be
reversed or topped up by hand, and lesson 14 shows why that is the point of no return in any
migration that moves money.

A big bang also delivers no value until it is finished. For two years the company pays for two
teams, one keeping Coleta alive and one building its replacement, and the only thing the board can
see is a date that has moved twice. Projects in that state lose their sponsors before they lose
their technical problems.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l13-risk\" aria-label=\"A chart with time in months on the horizontal axis, from 0 to 30, and, on the vertical axis, change that has been built but not yet proved in production. The big-bang line rises steadily for the whole project, from nothing at month 0 to its highest point at month 28, and drops to zero only at the cutover, where all of it is proved at once. The incremental line is a sawtooth that stays low: it rises for about four months, drops to zero when a slice goes live, and repeats six times.\"><defs><marker id=\"l13-risk-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90.0 250.0 L660.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-es-ah-paper-dim)\"></path><path d=\"M90.0 250.0 L90.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-es-ah-paper-dim)\"></path><path d=\"M90.0 250.0 L90.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"90.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M202.0 250.0 L202.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"202.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><path d=\"M314.0 250.0 L314.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"314.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><path d=\"M426.0 250.0 L426.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"426.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><path d=\"M538.0 250.0 L538.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"538.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><path d=\"M650.0 250.0 L650.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"650.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"370.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">months since the project started</text><text x=\"42.0\" y=\"141.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">built,</text><text x=\"42.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">not yet</text><text x=\"42.0\" y=\"168.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">proved</text><path d=\"M90.0 250.0 L612.7 70.0 L612.7 250.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"612.7\" cy=\"70.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"604.7\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cutover: all of it proved on one night</text><path d=\"M90.0 250.0 L187.1 226.0 L187.1 250.0 L272.9 226.0 L272.9 250.0 L358.8 226.0 L358.8 250.0 L444.7 226.0 L444.7 250.0 L530.5 226.0 L530.5 250.0 L616.4 226.0 L616.4 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"416.7\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">incremental: each slice proved when it goes live</text><text x=\"258.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">big bang</text></svg>", "caption": "The risk sits in work that nobody has yet seen running against real farms. A big bang lets it pile up for the whole project; a strangler releases it a slice at a time."}
```

The figure is the argument of this section in one shape. The quantity on the vertical axis is
**change that has been built but not yet proved in production**, which is where the risk sits:
work nobody has seen running against real farms. A big bang lets it pile up for the whole project
and releases it all on one night. An incremental replacement keeps the pile small, because every
few months something goes live, is checked against reality and stops being a risk.

## The strangler fig

In 2004 Martin Fowler gave the incremental approach the name that stuck. In a short article called
*StranglerFigApplication* he described the strangler figs he had seen in the rainforests of
Queensland. A fig seeds in the upper branches of a host tree, sends its roots down to the soil,
and over years grows around the host until it stands on its own and the host has died inside it.
**The software version builds the new system around the edges of the old one, moves its work
across one capability at a time, and switches the old one off when nothing is left inside.**

Three things change compared with a rewrite. Something goes live early, so the new system meets
real farms in month six rather than month thirty. Each move is small, so when one goes wrong the
damage is one capability and the way back is to route that capability to the old system again.
And the old system keeps doing everything that has not moved yet, so the changes the business asks
for in the meantime land in one place: wherever that capability lives at the time.

## What the strangler costs

It is not free, and the people paying for it should hear that before they agree. **For as long as
the migration lasts, both systems run, and the code that lets them run together is written to be
thrown away.** The routing in front of the old system, the translation between the two models,
the synchronisation of data that both need: all of it exists only for the middle of the migration,
and the middle is long. The total duration is usually longer than the rewrite's plan said, though
the rewrite's plan was rarely the duration it achieved.

So the strangler is not always the answer. A big bang is reasonable when the system is small,
when its rules are frozen and written down, when nothing calls it, or when coexistence would cost
more than the risk it removes. Replacing a stand-alone tool that ten people use, whose data can be
moved in an afternoon and checked by hand, does not need a migration programme. Coleta is the
opposite on every count: it is large, it changes every month, its rules are in its code, half the
company depends on its output and it moves money.

## Joana's decision

Joana's first draft of the plan, written in her second month, was a rewrite. She had built systems
from nothing for eight years and it was the plan she knew how to estimate. Edson read it and asked
one question: what would Serra Alta do on the 10th of the month after cutover if 200 farms had
been paid the wrong amount. The draft had no answer, and the second draft was a strangler.

Its shape is the rest of this lesson. A routing layer where Coleta has an edge, and interception
where it has none. A translation layer so the new model is not born in Coleta's image. A long
middle in which both systems run, with one owner for every piece of data at every moment. And an
end, written down with a date, when the IBM i is switched off. Whether the system that replaces
Coleta's payment calculation is bought, built or added to SAP is a separate question, and lesson
15 answers it. The strangler works the same way for all three.
