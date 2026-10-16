---
title: Why rewrites fail
version: 1
---

The proposal reached Davi in the week after the strategy was published. Mateus Araújo, the Checkout
tech lead, wanted to start again with two engineers from Payments: rewrite the reservation module
from scratch, with everything nine years had taught them. Every team's code reaches into that
module, so the rewrite would take the parts of `coreto-core` wired to it as well — six engineers,
eighteen months. The old code would keep running until the new one was ready, and then Coreto would
switch over. Davi refused it, and it is the line on the "what we will not do" list of lesson 3; this
lesson is the argument behind that line.

It is the most attractive proposal in software, and the reasons behind it are real. The monolith is
hard to change, the seat-hold code is the worst of it, and every engineer who has worked there can
sketch a better design. What the proposal gets wrong is three things at once: **what the old code
contains, how big the new one becomes, and what the old system does while it waits.**

## The old code is the documentation nobody wrote

In 2000 Joel Spolsky published "Things You Should Never Do, Part I", about Netscape's decision to
rewrite its browser from scratch, which left the company for years without a new major release while
its competitors kept shipping. His argument was about code rather than about Netscape. Old code looks
ugly because it has been fixed. Each odd branch, each special case that seems pointless, is often a
bug somebody met in production and a fix nobody wrote down anywhere else.

Coreto's reservation module is full of them. A condition releases holds early for one chain of
venues; a check handles the half-price tickets Brazilian law gives students, the *meia-entrada*; a
retry exists because a payment provider once answered the same request twice. Each looks like clutter
to a new reader, and each is a requirement. **A rewrite starts from the requirements people
remember.** The ones that live only in the code get rediscovered one at a time, in production, after
the switch.

## The second system

Fred Brooks named the next danger in *The Mythical Man-Month* in 1975: the second-system effect. The
designer of a first system is careful, because nobody yet knows what will work. The second time,
confident, the designer puts in everything that was held back — each generalisation, each deferred
feature. The second system comes out bigger and later than the first, and often slower.

Mateus's proposal already shows it. Its first page promises a clean reservation model. Its second
adds an event bus, a plugin system for venues and support for selling outside Brazil, and nobody at
Coreto has asked for any of them. Each addition is reasonable on its own. Together they turn an
eighteen-month estimate into something nobody can estimate at all.

## The moving target

**The old system does not stop while the new one is written.** Over eighteen months Coreto's seven teams
will keep shipping into `coreto-core`; the strategy alone puts a Reservations team to work on the
seat-hold code from 1 March. Every change made to the old system is a change the new one has to make
too before it can replace it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"A schematic chart with no numbers. The horizontal axis is time, the vertical axis is what each system does. The old system starts high and keeps rising. The new system starts at zero. The plan has it meeting the old system as it stood on the first day; because the old line keeps rising, the new line meets it much later and higher up.\"><defs><marker id=\"l06t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 30 L70 280 L690 280\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l06t-ah)\"></path><text x=\"380.0\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">time since the rewrite started</text><text x=\"80\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">what the system does</text><path d=\"M70 170 L690 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M70 280 L330 170\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></path><path d=\"M70 170 L330 170\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></path><circle cx=\"330\" cy=\"170\" r=\"5\" fill=\"var(--paper-dim)\"></circle><path d=\"M70 280 L490 102\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><circle cx=\"490\" cy=\"102\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"680\" y=\"58\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">the old system, still being changed</text><text x=\"338\" y=\"194\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the plan: catch up with the old</text><text x=\"338\" y=\"210\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">system as it was on day one</text><text x=\"478\" y=\"78\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">what happens: catch up with</text><text x=\"478\" y=\"94\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">a system that kept moving</text><text x=\"150\" y=\"262\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">the new system</text></svg>", "caption": "The moving target. A rewrite is estimated against the old system as it stands when the work begins, and the old system goes on changing while the new one is written."}
```

**A rewrite chases a target that keeps moving**, and the faster the company ships, the faster it
moves away. The choice is unpleasant either way. Freeze the old system, and the business waits a
year and a half for its features. Keep changing it, and the rewrite's finish line recedes. The six
engineers on the rewrite are six of 52 shipping nothing a customer sees, and the other 46 are making
their job bigger every sprint.

## Nothing until the end

The last problem is how the money is spent. A rewrite delivers nothing until the switch: eighteen
months of salaries with no change any venue or buyer can see, followed by one cutover at which every
difference between the two systems appears at once. If the new code is wrong about a seat hold, it is
wrong for every event on the same morning.

**The risk all lands on the one day the company can least afford it**, and at Coreto there is always
an on-sale coming. Compare the debts in lesson 5, where each payment starts saving hours in the
sprint after it lands.

## What the four have in common

| reason | what it costs |
|---|---|
| the knowledge lives in the old code | requirements rediscovered in production |
| the second-system effect | a scope that grows past any estimate |
| the moving target | a finish line that recedes, or a business that waits |
| value only at the end | every risk landing on a single cutover |

None of these is about the skill of the people proposing the rewrite. They are properties of the
approach, and they catch good teams as surely as weak ones. They also have conditions — size, change,
an irreversible switch — and the next section is about the two situations in which those conditions
stop holding.
