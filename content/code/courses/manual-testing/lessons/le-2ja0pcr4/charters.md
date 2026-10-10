---
title: Charters
version: 1
---

A **charter** is the mission of one session, written before it starts: what to explore, with what,
and what you are trying to find out. It is short, a sentence or two, and it does two jobs. It keeps
the session pointed somewhere, so that ninety minutes do not drift into whatever happened to be on
screen. And it tells everyone else what the session covered, so that a sheet saying "four sessions
on orders" means something.

## A template

Elisabeth Hendrickson's book *Explore It!* gives charters a three-part shape that most teams now use:

> **Explore** *a target* **with** *resources* **to discover** *information*.

The **target** is the part of the product: a feature, a page, a requirement, a kind of data. The
**resources** are what you bring: a tool, a data set, a technique, a heuristic, another account. The
**information** is the question the session is meant to answer, and it is the part that is most
often left out and most worth writing, because it is what tells you when the session has done its
job.

Here is Ana's charter for the session in section 05 of this lesson:

> Explore **the life of an order**, with **every action from every state, in the browser and with
> curl**, to discover **what the application allows and says that R6 and R7 do not spell out**.

The target is the order states of R6. The resources are the four actions and two ways to send them.
The information is the gap between what the requirements say and what the application does, which
is exactly what a script written from those requirements cannot see.

## Too wide, too narrow

A charter can miss in two directions, and both are common.

**Too wide**: *Explore boxoffice.* Nothing in it says where to start, when to stop or what a good
session would have found, so the session goes wherever the first interesting screen takes it and
the sheet afterwards says nothing a manager can use.

**Too narrow**: *Check that six tickets can be booked.* That is a test case with the word "explore"
in front of it. It has one expected result and leaves nothing to discover; it belongs in a suite,
and lesson 9 already ran it.

A good charter is wide enough to need judgement and narrow enough to be finished. A few more for
boxoffice 1.1, each one a session's worth:

- Explore **sign-up** with **names and addresses at and beyond R2's limits, and characters from other
  languages**, to discover how it treats input nobody typed on purpose.
- Explore **booking near a show's closing time** with **`BOXOFFICE_NOW` set to moments around it**,
  to discover what changes as a show gets close.
- Explore **the seat count** with **many small orders, cancellations and refunds**, to discover
  whether the number on the Shows page always matches what is sold.

## Where charters come from

Charters are kept in a list, fed from the same places as the rest of the testing. The risks of
lesson 1 say where a session is worth most. The requirements suggest charters too, especially the
ones whose scripted cases felt thin. A fresh defect is a reason to explore its neighbourhood. And
earlier sessions end their debriefs with questions that were not on their charter. The tester usually writes them, and the lead
decides with the tester which ones run this week.

## The time box

A session has a fixed length, chosen before it starts. Session-based test management uses about 90
minutes as a normal session, with short ones of about an hour and long ones of about two, and the
point of the box is that it is **uninterrupted**: no meetings, no messages, one charter. A session
that is interrupted every ten minutes is several short sessions, each spending its first minutes
finding its place again.

**The charter is a direction, and the session may leave it.** When something interesting appears
that is outside the charter, the tester writes it down as an *opportunity* and decides: follow it
now, if it is worth more than the rest of the charter, or leave it for a charter of its own. The
session sheet says how much time went to the charter and how much to opportunities, so that a
session spent mostly elsewhere is visible rather than hidden.
