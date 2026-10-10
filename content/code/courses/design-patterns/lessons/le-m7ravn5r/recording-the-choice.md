---
title: Recording the choice in a page somebody will read
version: 1
---

**A pattern choice that is not written down gets made again by whoever reads the code next, and
usually the other way.** The person who finds a dictionary of functions where they expected a
strategy hierarchy has no way to know it was deliberate. The person who finds a protocol with one
implementation has no way to know a second is planned for June. Both will "fix" it, and the
argument that settled the question is lost with the fix.

The lightweight answer is an **architecture decision record**, an ADR: a short page in the
repository, one per decision, numbered and never rewritten. `architecture` lesson 20 covers ADRs
properly, from where to keep them to how to defend one in a review. This section does not repeat
that. It shows what a record of a *pattern* choice needs that other records sometimes do not.

## What a pattern decision has to say

A pattern choice is unusually easy to undo by accident, because the code that implements it looks
like it could be "improved" in either direction. So the record has to carry three things the code
cannot:

- the force, in the one-sentence form from section 02, so a reader can check whether it still
  holds;
- the bigger answer that was rejected, and its cost, so nobody re-proposes it believing nobody
  thought of it;
- the condition that would reopen the decision, so the next person knows what to watch for
  instead of relitigating it on taste.

The third is the part section 05 called most often skipped. Without it, a record says what was
decided and leaves the reader to guess whether it still applies.

## Case 1 from section 05, as a record

The format below is Michael Nygard's, the most common one: a title, a status, the context, the
decision and the consequences. It fits on one screen, which is the point.

```localised
# 7. Fines: a rate table and a dictionary of rule functions

Status: accepted, 2026-10-10

## Context
The daily rate differs by member category (adult 50, student 25,
staff 0, senior 25 from next term). Films are capped at their price.
Categories change about once a term; the rules per kind of item have
changed once in three years.

## Decision
Rates live in a dictionary, DAILY_CENTS. Rules are plain functions
with one signature, chosen by kind of item from RULES.
We considered a strategy class per category, chosen by a factory.
Rejected: it puts a number into a class, and a new category would
mean a new class and a factory change instead of one line of data.

## Consequences
A new category is one line. A new rule is one function and one entry.
Every rule takes price, even the ones that ignore it.
Reopen if a rule needs its own state or configuration, such as a
fine that grows after a warning has been sent.
```

Notice what is not there. There is no description of the code, which the code already gives, and
no history of the meeting. The record is short enough that people read it, and it is in the
repository next to the code, so it travels with every copy and shows up in the same review as the
change it explains.

## When a record is worth writing

Not every function needs a page. A fair rule is to write one when a choice was argued, meaning
somebody proposed the alternative and it was turned down, or when the choice will look odd to a
reader who does not have the context. Two situations from this lesson qualify: a protocol with
one implementation kept on purpose deserves a record that says what the second implementation will
be, and a plain function kept where a pattern was proposed deserves one that says what force would
change that.

**A record is never edited to change its decision.** When the reopening condition arrives and the
choice changes, a new record is written, numbered after the last, and the old one's status becomes
*superseded by 12*. The history of why the code is shaped the way it is then reads in order, which
is the one thing a commit log is bad at telling you.
