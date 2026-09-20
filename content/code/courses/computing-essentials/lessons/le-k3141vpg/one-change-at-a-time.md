---
title: One change at a time, and write it down
version: 1
---

The most expensive habit in this whole subject is changing three things and finding that it
works. You have a working machine and no idea why, which means you cannot fix it the next time
and you cannot tell anybody else how.

## The rule

**Change one thing. Test. If it did not help, put it back.**

The third clause is the one everybody drops, and it is the one that does the work. A setting
changed, left in place and forgotten is a change that will be part of the next fault — and next
time it will be in the *what changed* answer as *nothing*.

## Why it is worse than it looks

Two changes made together have four possible explanations: the first fixed it, the second fixed
it, both were needed, or neither mattered and something else moved. You cannot tell them apart,
and none of the four is the knowledge you were trying to buy.

It gets worse with the ones that fix it by accident. **Restarting** is the classic: restart, and
change two settings, and it works, and now the two settings are part of the folklore of that
machine forever.

## The note

A piece of paper, or a text file on a phone, with three columns: what you changed, what you
expected, what actually happened.

It sounds like bureaucracy for a home. It is worth it for one reason: an investigation longer
than twenty minutes exceeds what anybody reliably remembers, and the specific failure is going
back to something you already tried because you could not remember whether you had. That loop can
eat an entire evening and it feels like progress the whole time.

## Undo is a feature of the method, not a tidy-up

**Everything you change should be something you can put back.** That is a constraint on which
changes to make, not only on how to record them:

- prefer a setting to an installation;
- prefer disconnecting a thing to reconfiguring it;
- before editing a configuration file, copy it;
- be suspicious of any step that ends *and then it cannot be undone.*

The reason is not caution for its own sake. It is that **a change you cannot undo turns one
variable into a permanent one**, and from that point on every test you run is on a different
machine from the one with the fault.
