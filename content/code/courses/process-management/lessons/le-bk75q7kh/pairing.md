---
title: Pairs and mobs
version: 1
---

**Pair programming** is two people at one computer working on the same code. One, the *driver*, types and thinks about the line in front of them; the other, the *navigator*, reads every line as it is written and thinks about where the code is going. They swap often, every half hour or every few tests. XP asks for all production code to be written this way.

To somebody who has never done it, pairing looks like paying two salaries for one keyboard. The argument for it is that the keyboard was never the bottleneck. Typing is a small part of programming; deciding what to type, noticing what is wrong and knowing how the rest of the system works are most of it, and two people do those better than one.

## What the evidence says

The research is smaller than the debate. A study by Laurie Williams and colleagues, published in 2000 with university students, found that pairs took somewhat more total effort than individuals working alone — on the order of 15% more person-hours — and produced code with fewer defects. Later studies with professionals found smaller and more mixed effects, depending on how hard the task was and how experienced the people were. **The honest summary is that pairing costs some effort and buys fewer defects and shared knowledge**, and whether the trade is worth it depends on the work. A complex, risky change is the strongest case; a routine one is the weakest.

## Knowledge is the larger benefit

The benefit that is easiest to see in a team is not defects but **who knows what**. On a team where every piece of code was written by a pair and the pairs rotate, at least two people know every part of the system. Nobody is the only person who understands billing, so nobody's holiday stops billing work, and the departure lesson 11 lists among the Agenda team's risks loses most of its impact. XP calls the result **collective code ownership**: any pair may change any code, because every part has been seen by more than one person.

## Mob programming

**Mob programming**, now often called *ensemble programming*, takes the idea further: the whole team at one screen, one driver, everybody else navigating, the driver rotating every few minutes. Woody Zuill's team made it known in the early 2010s. It sounds even more wasteful than pairing and it is used for exactly the work where pairing pays most: a hard design decision, an unfamiliar part of the system, onboarding a new member. Few teams mob all day; many mob for the hour when a decision needs everybody.

## What a lead should watch

Pairing goes wrong in recognisable ways: one person types for hours while the other watches their phone; an experienced developer dictates and the junior one transcribes; two people who cannot work together are paired every day. **Rotation fixes most of it**, and a pair should be free to split for an hour when the work is routine. Pairing that is imposed as a rule and never discussed tends to be quietly abandoned, which is worse than deciding openly where it is worth its cost.
