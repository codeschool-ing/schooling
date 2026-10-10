---
title: A checklist for the next pattern you reach for
version: 1
---

**The whole lesson fits in a few questions, asked in order, before a pattern goes in and again when
somebody proposes taking one out.** A checklist is not a substitute for judgement. It is a way of
making sure judgement is applied to the right things, in the right order, on the day you are tired
and the pattern looks obvious.

The order matters. Each question is cheaper to answer than the one after it, and a "no" early on
saves the rest.

## Before adding a pattern

1. What is the force, in one sentence? Something changes and the change is expensive, or a part
   knows what it should not. If the sentence will not come, or comes out as "it would be cleaner",
   stop here.
2. Is the force real today? Point at it: the third copy of the same `if`, the change log that
   keeps touching the same five files, the test that needs a mail server. A force predicted for
   next year is a reason to keep the code easy to change, not a reason to build the structure now.
3. What is the smallest answer? A dictionary, a function passed as an argument, a module-level
   object, a list of callables. Python, Go, TypeScript and modern Java all make the small forms
   cheap, which was lesson 6's point about patterns built into the language.
4. What does it cost a reader? Count the files and the hops to answer the commonest question
   about this code, as `hops.py` did. Compare that with how often the change it absorbs will
   happen.
5. What happens under concurrency? Lesson 18's question: who else can be here at the same
   time? A lazily built singleton or an observer list that changes during a walk is a new bug, not
   a pattern.
6. What would reopen the decision? Write it down, in an ADR if the choice was argued, beside the
   code if it was not.

## Before removing one

The same questions, read from the other side. Speculative structure is worth removing, and
structure that answers a force you cannot see is worth leaving. Before deleting an interface, look
for the second implementation in the tests. Before collapsing a layer, look for the rule or the
translation it performs. Before replacing a dictionary of functions with a hierarchy, or the other
way round, look for the record that says why it is the way it is. **Removing a pattern is a design
decision too, and it deserves the same evidence as adding one.**

## The CV in the title

The lesson's title names a pressure worth admitting. Patterns are a vocabulary that interviews and
reviews reward, and using one is a way to show that you know it. That is not a bad motive in a
lesson, a kata or a side project, where the point is to learn the shape. It is a bad motive in
code that other people will read for years, because the cost of the demonstration falls on them.

The evidence that you understand a pattern is not that you used it. It is that you can say which
force it answers, what it costs, and when you would take it out again. Every lesson in this course
has tried to give you that for one family of patterns, and the course that follows,
`architecture-modeling`, draws the same patterns as models, where the forces and the costs have to
be stated before anything is built.
