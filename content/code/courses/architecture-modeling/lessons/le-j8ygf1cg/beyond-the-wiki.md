---
title: What keeps a document alive, and what this lesson adds
version: 1
---

**`architecture-role` lesson 8 set out the habits that keep documentation true: keep it in the
repository as plain text, change it in the same pull request as the code, give every page an owner
and a date, check what can be checked, and delete what nobody will maintain.** This lesson assumes
those habits and goes on to the questions they leave open.

## Four questions the habits do not answer

1. **What should an architecture document contain?** Owners and dates keep pages true; they do not
   say which pages should exist. A template does, and arc42 is the one most teams use.
2. **What kind of page is this?** A tutorial for a new engineer and the reference page listing every
   endpoint decay differently and need different upkeep. A small classification, Diátaxis, sorts them.
3. **How do we know the architecture still matches the documents?** Checking by hand does not scale.
   **Fitness functions**, automated checks of architectural properties, do it on every change.
4. **How healthy is the documentation as a whole?** Individual owners cannot see that. A handful of
   numbers can.

And a fifth, which `architecture-role` lesson 8 started and this lesson finishes: **how does a page
die well?**

## Carcará's starting point

Tainá counted the architecture repository after the digital boarding programme of lesson 8: **140
pages, 31 edited in the past twelve months**, 23 decision records, 14 diagrams, three of which showed
the station back office that had been retired. Nobody could tell which of the other 109 pages were
still true, so in practice nobody trusted any of them, and engineers asked Tainá instead. That last
fact is the real cost of dead documentation: **the knowledge goes back into one person's head**,
which is exactly what writing it down was meant to prevent.

The rest of this lesson follows what Carcará did about it, in about two weeks of work spread over a
quarter.
