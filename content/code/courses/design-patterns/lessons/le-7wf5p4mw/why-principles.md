---
title: What a design principle is for
version: 1
---

**A design principle is a rule of thumb about where change will hurt, written down by somebody who
was hurt by it often enough.** It does not tell you what to build. It tells you which arrangement of
the same code will be cheaper to change next month, and it is worth exactly as much as the change it
predicts.

The common misreading is to treat principles as laws: code that follows SOLID is good, code that
breaks it is bad, and a reviewer can tick the letters off. That reading produces the over-built
code lesson 4 ends with, where every class has an interface and nobody can find the line that does
the work. A principle is a question to ask when something is hard to change, not a checklist to run
before anything exists.

## Where the five letters came from

Robert C. Martin collected the principles in articles and a paper, *Design Principles and Design
Patterns*, around 2000. Two of them are older than the collection: the open/closed principle is
Bertrand Meyer's, from his 1988 book *Object-Oriented Software Construction*, and the substitution
principle is Barbara Liskov's, from a keynote in 1987. Michael Feathers noticed that the initials
could be arranged into a word, and the word stuck.

| letter | principle | the question it asks | lesson |
|---|---|---|---|
| S | single responsibility | who will ask for this code to change? | 3 |
| O | open/closed | can a new case be added without editing working code? | 3 |
| L | Liskov substitution | can every child be used where its parent is expected? | 3 |
| I | interface segregation | does each client depend only on what it uses? | 4 |
| D | dependency inversion | does the policy depend on the detail, or the other way round? | 4 |

All five are about **dependencies**: which piece of code has to know about which other piece, and
therefore which piece breaks when another one changes. That is also what lesson 2 was about. The
fragile base class is a child depending on its parent's insides; the class explosion is every
combination depending on every axis. SOLID gives names to five shapes of that problem.

## What each one costs

Every principle in this lesson, applied, adds something: a class split in two, a protocol where
there was a concrete class, a function that takes a part instead of building one. Each addition
is a place a reader has to look. The trade is worth making when the change it protects against is
likely, and it is pure cost when that change never comes.

So read each section with two questions in hand. What change does this principle make cheap? And
in the code you work on, how often does that change actually happen? The programs in this lesson
are chosen so that the change happens on the page, in front of you, with the output to show what it
broke or did not break.

## Principles and patterns

A pattern is a named solution with a known shape: a strategy, an adapter, a repository. A principle
is the reason a pattern has that shape. Lesson 6's catalogue of patterns reads much more easily once
these five are familiar, because most of the patterns in it are one of the principles applied to a
particular, recurring problem. **The principle is the argument; the pattern is the argument already
made for one case.**
