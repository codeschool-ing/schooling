---
title: The manifesto, and what it says about testing
version: 1
---

**In February 2001, seventeen people who had each been developing lighter ways of building software met
at a ski resort in Utah and wrote a page.** The *Manifesto for Agile Software Development* is four
sentences of values and twelve principles, and it gave a name to a family of methods, Scrum, Extreme
Programming and several others, that already existed and had something in common.

The four values are written as preferences:

> **Individuals and interactions** over processes and tools.
> **Working software** over comprehensive documentation.
> **Customer collaboration** over contract negotiation.
> **Responding to change** over following a plan.

The sentence that follows them is the one most often forgotten: *while there is value in the items on the
right, we value the items on the left more.* The manifesto does not reject plans, documents or processes.
It ranks them.

## Three misreadings that affect testers

**"Agile means no documentation."** It means documentation that earns its place. A test plan nobody reads
is waste; a list of the examples that define a price rule, kept beside the code and run every day, is
documentation of the most valuable kind. Lessons 16 and 17 are about exactly that.

**"Agile means no testers."** The manifesto does not mention testers at all, and some teams read the
silence as dismissal. The principles say the opposite in different words: *working software is the primary
measure of progress*, and *continuous attention to technical excellence and good design enhances agility*.
Somebody has to know whether the software works. What changes is that testing is no longer a department
downstream; lesson 5's whole-team approach is the agile answer to who does it.

**"Agile means no planning."** It means planning in short horizons and re-planning often. That changes
testing more than any other activity, because the thing being tested changes every two weeks.

## What the values change for testing

Take the second value literally: **working software** is how progress is measured. Not documents, not
percentages of a plan: software that works, in front of the people who will use it. For that statement to
mean anything, somebody has to establish, every couple of weeks, that the software does work. Testing stops
being a phase at the end and becomes **the way the team knows it has made progress at all**.

The fourth value has a cost the testing side pays. Responding to change means the requirement Lia tested
last month may be different this month, and the tests have to change with it. A team that cannot change its
tests as fast as its code has quietly stopped being able to respond to change, whatever its process says.
