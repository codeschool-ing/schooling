---
title: Architecture is not a phase
version: 1
---

There are two opposite mistakes about when architecture happens, and each is a reaction to the
other. **One treats architecture as a phase at the start of a project**: a design is written,
approved and handed over, and coding begins. **The other treats it as something agile teams do not
need**: write code, refactor, and let the design emerge. Both fail, in different ways, and the
working answer sits between them and lasts for as long as the system does.

## Big design up front

The first mistake has a name, *big design up front*. A team spends months on a complete design
before anybody writes code, so that the code only has to follow it. The appeal is real: decisions
made early, on paper, are cheap to change, and a team that knows where it is going wastes less work.

The trouble is that **most of what the design depends on is not yet known.** How many shippers will
use the product, which features they will actually want, where the load will concentrate, what the
regulator will change next year. A design that fixes all of that in advance is a set of guesses, and
the guesses are hardest to correct exactly when they turn out wrong, because by then code has been
built on them. A design document that was approved and never revisited becomes the slide of the
previous section: a plan presented as a description.

## No design at all

The opposite mistake grew out of the reaction to the first. Extreme Programming and the agile
movement argued, correctly, that much design can be done in small steps as the code grows, guided by
tests and refactoring. Martin Fowler's essay "Is Design Dead?" examined that claim and concluded
that design is not dead but changes shape. Some teams heard only the first half and stopped deciding
anything in advance.

**Some decisions cannot be refactored later at a reasonable price.** The shape of the data that
three teams share, the way money is moved, whether a step can be retried safely: once code and data
depend on these, changing them is a project rather than a refactoring. Carreto's shared `loads`
table is the result of years of not deciding. Each step was small and sensible; the sum is the most
expensive decision in the system, and nobody made it.

## Just enough, at the right moment

The working answer is to decide **just enough up front**: the decisions that would be expensive to
change, and no others. Lesson 1's test does the sorting. Anything with a high cost of change, or
that crosses team boundaries, is decided deliberately and early enough to matter. Everything else is
left to the team building it, to be decided when they know more.

The question of *when* exactly has a useful answer, from Mary and Tom Poppendieck's *Lean Software
Development* (2003): the **last responsible moment**, the point at which failing to decide would
eliminate an important alternative. Before it, deciding means guessing with less information than
you could have. After it, the decision is made for you, by default, by whatever the code already
does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A conceptual chart with time on the horizontal axis and cost on the vertical. One curve, the cost of guessing, falls as information arrives. The other, the cost of waiting, rises as work is built around the open decision. A dashed vertical line where they cross is marked the last responsible moment; to its left a decision is a guess, to its right it is made by default.\"><defs><marker id=\"lrm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 270 L680 270\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lrm-ah)\"></path><path d=\"M70 270 L70 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lrm-ah)\"></path><text x=\"370.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">time, as the project learns more</text><text x=\"60\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">cost</text><polyline points=\"70.0,80.0 80.0,85.6 90.0,91.1 100.0,96.6 110.0,101.9 120.0,107.2 130.0,112.3 140.0,117.4 150.0,122.3 160.0,127.2 170.0,131.9 180.0,136.6 190.0,141.2 200.0,145.7 210.0,150.1 220.0,154.4 230.0,158.6 240.0,162.7 250.0,166.7 260.0,170.6 270.0,174.4 280.0,178.2 290.0,181.8 300.0,185.4 310.0,188.8 320.0,192.2 330.0,195.4 340.0,198.6 350.0,201.6 360.0,204.6 370.0,207.5 380.0,210.3 390.0,213.0 400.0,215.6 410.0,218.1 420.0,220.5 430.0,222.8 440.0,225.0 450.0,227.1 460.0,229.2 470.0,231.1 480.0,233.0 490.0,234.7 500.0,236.4 510.0,237.9 520.0,239.4 530.0,240.7 540.0,242.0 550.0,243.2 560.0,244.3 570.0,245.3 580.0,246.2 590.0,247.0 600.0,247.7 610.0,248.3 620.0,248.8 630.0,249.2 640.0,249.6 650.0,249.8 660.0,250.0 670.0,250.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></polyline><polyline points=\"70.0,258.0 80.0,258.0 90.0,257.9 100.0,257.7 110.0,257.5 120.0,257.2 130.0,256.8 140.0,256.3 150.0,255.7 160.0,255.1 170.0,254.3 180.0,253.5 190.0,252.5 200.0,251.4 210.0,250.3 220.0,249.0 230.0,247.6 240.0,246.1 250.0,244.6 260.0,242.9 270.0,241.1 280.0,239.1 290.0,237.1 300.0,235.0 310.0,232.7 320.0,230.3 330.0,227.8 340.0,225.2 350.0,222.5 360.0,219.6 370.0,216.6 380.0,213.6 390.0,210.3 400.0,207.0 410.0,203.5 420.0,200.0 430.0,196.2 440.0,192.4 450.0,188.4 460.0,184.4 470.0,180.1 480.0,175.8 490.0,171.3 500.0,166.7 510.0,162.0 520.0,157.1 530.0,152.1 540.0,147.0 550.0,141.7 560.0,136.3 570.0,130.8 580.0,125.1 590.0,119.3 600.0,113.4 610.0,107.3 620.0,101.1 630.0,94.8 640.0,88.3 650.0,81.7 660.0,74.9 670.0,68.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></polyline><path d=\"M390.0 270 L390.0 60\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></path><text x=\"390.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the last</text><text x=\"390.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">responsible moment</text><text x=\"90\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">cost of deciding now:</text><text x=\"90\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">guessing without the facts</text><text x=\"590\" y=\"63.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cost of waiting: work built</text><text x=\"590\" y=\"77.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">around the open decision</text><text x=\"180\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">too early:</text><text x=\"180\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a guess</text><text x=\"570\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">too late:</text><text x=\"570\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">decided by default</text></svg>", "caption": "No numbers, only the shape: deciding early costs guesses, deciding late costs the work built around the gap. The last responsible moment is where the second starts to outgrow the first."}
```

The moment is the last *responsible* one, not the last possible one. **Waiting is not free**: while
a decision is open, teams build around the gap, and every week adds work that the eventual decision
may have to undo. A decision deferred past its moment has not been avoided. It has been taken by
accident.

## Two decisions in Payments

In Renata's third week, Bruno Farias brings her the plan for paying drivers by Pix through a bank
partner. Several decisions are in it, and they do not all have the same moment.

**How a payout is made safe to repeat is due now.** If Carreto sends a payment request, the bank
takes too long to answer and Carreto sends it again, the driver may be paid twice. Whether every
request carries a key the bank uses to refuse duplicates has to be settled before the first real
payout. The cost of getting it wrong arrives in money, on the day it goes live, and recovering a
payment from a driver is slow and damages trust. This decision is architectural on every count: it
crosses Payments and the bank, and it is very expensive to change once money has moved.

**Which client library talks to the bank can wait.** It is inside Payments, it can be swapped behind
an interface in a few days, and the team will know far more about the bank's API after a month of
using it in its test environment. Deciding it now would be deciding with less information for no
gain.

Lesson 3 comes back to the first of these, because the way it was decided turns out to matter as
much as what was decided.

## Decisions are revisited

The last part of the mistake is the idea that a decision, once made, is finished. **An architectural
decision is made in a context, and when the context changes the decision has to be looked at
again.** In 2017 Carreto's founders built one Django application with one database. With six
engineers and no customers, that was a good decision: one thing to deploy, one place for the data,
nothing to coordinate. With fifty engineers in seven teams, the same decision produces the 40-minute
deploys and the clashes over the `loads` table that the previous section listed.

The founders were not wrong. **The context moved, and nobody went back to the decision.** That is
the real job that "architecture is not a phase" describes: keeping a record of what was decided and
why, so that a change of context can be noticed and the decision reopened on purpose rather than
eroded by accident. Lesson 5 gives the tool for it, the architecture decision record, including what
happens to one when it is replaced.

So architecture happens before the code, during it, and for as long as the system runs. It is not a
document handed over at the start; it is a set of decisions that somebody keeps deciding.
