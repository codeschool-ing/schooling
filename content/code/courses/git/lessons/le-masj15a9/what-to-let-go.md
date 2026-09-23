---
title: What to let go, and when to approve
version: 1
---

The hardest skill in review is not finding things. It is **not writing** most of what you find.

## Let go of preferences

Ana would have offered a list of times instead of a free time field. That is a preference: both work, and
the one Bruno chose is not worse, only different. Writing it down asks him to rework something that is
fine, and it teaches him that every choice he makes will be reopened. The fourth row of the figure is
never written for that reason.

A useful test before posting: **would the code be worse in a way somebody could notice if my comment were
ignored?** If not, it is a preference, and it stays in your head or, at most, goes in as a `nit:` the author
is free to ignore.

## Move what is out of scope

The heading colour change is a different problem. It may be a good idea, but it is not part of ticket #30,
and it changes every page of the site inside a pull request about ordering. The right comment asks for it to
move, not for it to be undone forever:

> The heading colour change affects every page. Could it go in its own pull request, so it gets its own review?

That keeps #31 about #30, and if the new colour is later reverted, the order form does not go with it.

## Approve with comments

When only nits are left, **approve and leave them**. Every hosting service lets you approve and comment at
the same time. Holding a pull request back for a better button label costs the author a day and the team a
merge, and it buys almost nothing. Ana's review of #31 is one blocking comment, one question, one nit and one
request to move the colour change. Once `required` is in and the question is answered, she approves.

## Be quick

A review requested and not answered for three days is the most common way a pull request dies: the branch
drifts, the author moves on to other work, and coming back costs more each day. Many teams agree to a first
response within a working day. Half an hour of reviewing today is worth more than a perfect review on
Friday.
