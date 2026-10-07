---
title: Simple design, refactoring and the architect
version: 1
---

XP's design advice is short and has caused more arguments with architects than anything else in agile. It says: **build the simplest design that works for the stories you have today**, and change it when the next story needs something different. Do not build for requirements you are guessing at.

## The four rules

Beck stated simple design as four rules, in priority order. The code:

1. passes all the tests;
2. reveals its intention, so a reader can tell what it is for;
3. contains no duplication;
4. has the fewest elements — classes, functions, layers — consistent with the first three.

The slogan that goes with them is **YAGNI**, *you aren't gonna need it*: the configurable plug-in architecture for the three payment providers the company might one day support is not built while there is one provider. If the second one arrives, the design changes then.

## Refactoring makes it safe

Simple design only works if changing the design later is cheap. **Refactoring** — improving the structure of code without changing what it does, in small steps, with the tests passing after each — is the practice that makes it cheap. Martin Fowler's book of that name, from 1999, catalogued the steps. Without tests, refactoring is just editing, and nobody dares do it; with them, it is the third step of every turn of the test-first loop.

## Where an architect pushes back, and is right

YAGNI is an argument about decisions that are cheap to reverse. For those it is right: speculative generality costs time now, and usually the guess was wrong. Some decisions are not cheap to reverse, and lesson 2's last section named them — the data store, the boundaries between services, how identity works. A team that applies YAGNI to those builds the simplest thing for one clinic and discovers, at the fortieth clinic, that the data of every clinic is in one table with no way to separate it.

The reconciliation most practitioners settled on is to **separate the reversible from the irreversible**. Reversible decisions are made late and simply, as XP says. Irreversible ones get deliberate thought early, often a spike, and a written record of why. That is not a contradiction of XP; it is the same economics — spend effort where a late change would be expensive — applied to the decisions where it is.

## What the practices need from management

Every practice in this lesson costs something visible and pays back in something less visible. Pairing shows two people on one task; tests show time spent on code the user never sees; refactoring shows a week in which the features did not change. A manager who measures only visible output will cut all three, and the cost-of-change curve will rise again, slowly, until a late change costs what lesson 1 said it used to. Recognising that trade, and defending it, is part of what a technical lead is for. Lesson 14 gives the cost a name: technical debt.
