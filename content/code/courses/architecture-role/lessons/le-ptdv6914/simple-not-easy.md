---
title: Simple is not the same as easy
version: 1
---

"Keep it simple" is advice everybody agrees with, which is a sign that people hear it differently.
Most of the time it is taken to mean "do what is familiar" or "do what is quickest today". **Rich
Hickey, in a 2011 talk called "Simple Made Easy", pulled those two words apart, and the separation
is one of the most useful tools an architect has for arguing about a design.**

## Two words, two axes

**Simple** comes from the Latin *simplex*, one fold, and Hickey uses it for a thing that is not
intertwined with other things: one role, one concept, one reason to change. Its opposite is
*complex*, braided together. He revived an old English verb for the act of making things complex,
*to complect*, to braid together, and it has stuck among people who watched the talk. Simplicity is
a property of the thing itself. You can look at a design and count what each part is tangled with,
and two people counting will mostly agree.

**Easy** comes, by Hickey's account, from a root meaning near at hand. Easy is what is close to us:
familiar, already installed, within the skills we have today. **Easy is relative to a person, and
simple is not.** A streaming platform is easy for somebody who has run one for five years and hard
for somebody who never has, and it is exactly as tangled in both cases.

Because the two are independent, every choice sits somewhere on both axes at once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"A two-by-two grid. Columns: hard, unfamiliar today; and easy, close at hand. Rows: simple, one fold; and complex, braided. Simple and hard: worth the effort, Tracking tells Payments through an interface it owns. Simple and easy: take it, a function call inside the monolith. Complex and hard: avoid, a new streaming cluster for one team&#x27;s events. Complex and easy, highlighted: the trap, Payments reads Tracking&#x27;s tables directly.\"><defs><marker id=\"simpleeasy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"255\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">hard: unfamiliar today</text><text x=\"535\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">easy: close at hand</text><text x=\"60\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">simple</text><text x=\"60\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one fold</text><text x=\"60\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">complex</text><text x=\"60\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">braided</text><rect x=\"120\" y=\"64\" width=\"270\" height=\"128\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">worth the effort</text><text x=\"255\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tracking tells Payments</text><text x=\"255\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">through an interface it owns</text><rect x=\"400\" y=\"64\" width=\"270\" height=\"128\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">take it</text><text x=\"535\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a function call</text><text x=\"535\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">inside the monolith</text><rect x=\"120\" y=\"204\" width=\"270\" height=\"128\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">avoid</text><text x=\"255\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a new streaming cluster</text><text x=\"255\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">for one team&#x27;s events</text><rect x=\"400\" y=\"204\" width=\"270\" height=\"128\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">the trap</text><text x=\"535\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Payments reads</text><text x=\"535\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tracking&#x27;s tables directly</text></svg>", "caption": "Hickey's two words as two axes, with choices Carreto actually faced. The highlighted corner is the one that looks like good sense on the day it is chosen."}
```

The corner that causes trouble is the bottom right, easy and complex: the choice that is close to
hand today and braids things together for the future. The top left, simple and hard at first, is
where much of an architect's work is spent, persuading a team that the unfamiliar option will cost
less every time the code changes.

## How an easy choice tangles a system

When Payments first needed to know that a delivery had been proved, the easy path was obvious. The
Tracking database was right there, a read-only user already existed, and a query that read the
proof table worked on the first day. **It was easy, and it braided two teams together through one
table.** Six months later Tracking could not rename a column without breaking Payments, and a
routine Tracking migration once stopped payouts for 40 minutes on a Friday afternoon.

The simple path, in which Tracking tells Payments through an interface it owns and can keep stable,
took about a week to build. That week bought a property that every later change benefits from: the
two teams can change their own internals without asking each other. The decision record in lesson 5
is about exactly this question, and lesson 9 turns the general rule into a standard a machine can
check.

**Simple does not mean fewer boxes.** Splitting a monolith into services can untangle things, when
each service owns one concept and its own data. It can also tangle them further, when the services
share a database or have to be deployed together, the shape people call a distributed monolith:
every cost of services from lesson 2 of `architecture`, and none of the independence. The removals
in the previous section were simplifications because each one removed a braid: Pricing's ability to quote no longer depends on
whether pricing-floor is up. Taking a box away and leaving its tangles behind would have simplified
nothing.

## Start simple and let it grow

John Gall, in his 1975 book *Systemantics*, put it as a law: a complex system that works is
invariably found to have evolved from a simple system that worked, and a complex system designed
from scratch never works and cannot be patched to make it work. It is an aphorism rather than a
measurement, and it describes Carreto's history well. The monolith worked from the first year, and
the services that earned their place, Tracking first, were carved out of it when a real load
demanded it. The ones that did not earn it were mostly designed in advance, for loads that never
came.

## Choose boring technology

The same argument applies to technology, and Dan McKinley made it in a 2015 essay called "Choose
Boring Technology", written from his years at Etsy. His device is the **innovation token**. A
company gets a small number of them, about three, to spend on technology that is new to it, and
each new database, language or platform spends one. Spend them where the company is trying to be
different, and use boring technology everywhere else.

Boring does not mean bad. It means that the technology's failure modes are known, to the company
and to the internet: when it breaks at 3 a.m., somebody has seen that break before and written down
what to do. A new technology's failure modes are unknown until it fails, and its cost is paid by the
whole company for as long as it runs, while the benefit goes to the team that wanted it. McKinley
also argued that a company is better served by a small set of tools that everybody knows deeply
than by the best tool for each job, because every tool added makes the system as a whole harder to
operate.

Renata found Carreto's tokens already spent in the inventory. One was well spent: Tracking's store
for GPS positions, which takes about 270 writes a second at peak and is the kind of load where the
boring choice runs out. One was spent on load-search's search cluster, for a screen 4% of shippers
use. When the Matching team later proposed a graph database for choosing candidate drivers, she did
not refuse. She asked them to write down what it would buy that PostgreSQL could not at Carreto's
volume, and to try the PostgreSQL version first. It met their target in a week, and the token stayed
in the drawer.

**Two questions sum up the lesson for any proposal that adds something.** What will this be
tangled with? And is it worth one of the few tokens the company has? Lesson 6's decision matrix is
where those answers get weighed against the benefits, and lesson 17 shows what a system looks like
when nobody asked them for a long time.
