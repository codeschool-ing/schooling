---
title: Four definitions and what they share
version: 1
---

Ask a room of engineers what software architecture is and three answers come back quickly: the
diagram on the wiki, the high-level design, and whatever the architect decided. **The first is a
picture of the thing, the second only moves the question to the word "high", and the third is
circular.** The people who have studied the subject for more than thirty years do not agree on one
sentence either, but their definitions overlap, and the overlap is usable.

## Four definitions

**The standard.** ISO/IEC/IEEE 42010, the international standard for describing architectures,
defines it in its 2011 edition as the "fundamental concepts or properties of a system in its
environment embodied in its elements, relationships, and in the principles of its design and
evolution". It is a committee sentence, and every phrase in it was argued over. Three of them matter
here: *elements*, *relationships*, and *in its environment*. The standard does not say the
architecture is a document. A document describes it.

**The textbook.** Len Bass, Paul Clements and Rick Kazman, in *Software Architecture in Practice*,
define the software architecture of a system as "the set of structures needed to reason about the
system", made of software elements, the relations among them, and the properties of both. Two words
do the work. *Structures* is plural: a system has a module structure (how the code is divided), a
runtime structure (what runs and how it talks), and an allocation structure (where it runs and which
team owns it), and no single one of them is the architecture. *Reason* says what the structures are
for — predicting how the system will behave when it is loaded, attacked, changed or broken.

**The cost of change.** Grady Booch put it in one line that is quoted more than any other: "All
architecture is design, but not all design is architecture. Architecture represents the significant
design decisions that shape a system, where significant is measured by cost of change." This is the
definition you can use on a Tuesday afternoon, because it gives you a test.

**The important stuff.** Martin Fowler, in his 2003 column "Who Needs an Architect?", reports a
remark of Ralph Johnson's: architecture is about "the important stuff. Whatever that is." It sounds
like a joke and it is a serious point. Johnson also described architecture as the shared
understanding that the expert developers have of the system's design, and that puts it in people's
heads as well as in the code. What counts as important depends on the system, so no list of
"architectural topics" can settle it in advance.

## What they share

Laid side by side, the four definitions share four ideas:

| | elements | relations | environment | cost of change |
|---|---|---|---|---|
| ISO/IEC/IEEE 42010 | elements | relationships | "in its environment" | "evolution" |
| Bass, Clements and Kazman | software elements | relations among them | properties needed to reason | implied by "reason" |
| Booch | — | — | — | the measure of "significant" |
| Johnson, via Fowler | — | — | what makes something important | "the important stuff" |

**Elements and relations** are the structure: the pieces and how they connect. **Environment** is
everything the structure answers to — the users, the regulators, the teams, the people on call.
**Cost of change** is what separates an architectural decision from an ordinary one. Section 04 and
section 05 of this lesson take relations and environment in turn. This section stays with the other
two: elements, which come in more than one structure, and cost of change, the test Renata uses
first.

## Three structures at Carreto

The plural is easiest to see at Carreto, where the three structures tell three different stories
about the same system.

**The module structure** is how the code is divided. Inside the monolith there are about thirty
Django apps — `loads`, `quotes`, `invoices`, `drivers` and so on — and the rules about which may
import which exist only in people's heads. Outside it, each separate service is its own codebase.

**The runtime structure** is what runs and how it talks: the monolith, the 14 deployable services
(the monolith among them), the broker, the databases, and the calls and messages between them. This
is the structure an incident happens in, and section 04 of this lesson is about its lines.

**The allocation structure** is where each piece runs and who owns it: which machines, which cloud
account, and which of the seven teams answers when it breaks. Two pieces of code can sit side by
side in the module structure and belong to different teams in this one, which is how Carreto ended
up with three teams editing one table.

None of the three is "the" architecture. **A question about speed is answered from the runtime
structure, a question about who can change what from the module and allocation structures**, and an
architect has to be able to move between them.

## The test, applied at Carreto

In her first week as architect, Renata makes a list of decisions that already exist in Carreto's
system, made by somebody at some point and never written down. She does not ask whether each one is
"high level". She asks what it would cost to change it.

| decision already in the system | rough cost to change | architectural? |
|---|---|---|
| Pricing uses one HTTP client library rather than another | about two days for one engineer | no |
| the Driver app's screens are built with one UI framework | months for the Driver team, but only for that team | for the Driver app, yes; for Carreto, barely |
| Payments, Matching and the Shipper app all read and write the monolith's `loads` table | four to six months across three teams, with migrations in production | yes |
| Tracking owns its database and nobody else connects to it | already paid for; reversing it would be a choice, not a cost | yes, and a good one |
| quotes are calculated in reais with two decimal places | small in code, large in data: every stored quote and invoice | yes, though nobody thinks of it as one |

Three things show up in that table. **The size of a decision is not the size of the code.** The
currency precision is a few lines and touches every financial record Carreto holds. **Who is
affected matters as much as how long it takes.** The UI framework is expensive for one team and
nearly free for everybody else, which is why lesson 4 separates architecture at the level of one
application from architecture across several. And **some architectural decisions were never made on
purpose**: nobody decided that three teams should share the `loads` table. Each team needed the
data, the table was there, and the coupling arrived one query at a time.

## Every system has one

That last point leads to the one the next lesson starts from. **A system has an architecture whether
or not anybody drew it, chose it or knows what it is.** Carreto's shared `loads` table is part of
its architecture today, although no document mentions it. The question is never whether a system has
an architecture; it is whether the people working on it know which one, and whether anybody is
deciding it on purpose.

That is the job Tomás has just given Renata. Lesson 3 asks what the job is and where its authority
comes from. Before that, lesson 2 clears away three things architecture is commonly mistaken for.
