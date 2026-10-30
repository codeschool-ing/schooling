---
title: The kinds of lock-in
version: 1
---

"Lock-in" is usually said as one word for one fear: that a provider has you and will raise the
price. **It is at least five different things, and they cost different amounts to undo**, so a
team that treats them as one either refuses everything useful or notices nothing until the day it
wants to leave.

## Five kinds

**Data gravity.** Data is the heaviest thing a system owns. A terabyte in Cloud Storage costs
money to move out, takes time to copy and has to stay consistent while it moves, and every service
that reads it tends to settle near it. Section 04 puts the price on the first of those.

**Proprietary interfaces.** Pub/Sub, Firestore, Spanner and Cloud Tasks each have an API that
exists nowhere else. Code that calls them directly has to be rewritten to leave, and the rewrite
is proportional to how many places call them, not to how big the system is.

**Platform configuration.** A Cloud Run service's revisions and traffic split (lesson 9), a managed
instance group's update policy (lesson 4), an Eventarc trigger's filters (lesson 18): none of it is
in your code, all of it shapes how the code behaves, and all of it is written in Google's terms.
It is cheap to rewrite and easy to forget.

**Identity and permissions.** Service accounts, IAM roles, Workload Identity (lesson 15). Every
other provider has the same ideas under different names and different rules, and permissions are
the part of a migration that fails quietly: a service that starts and then cannot read anything.

**Commitments.** A committed use discount buys up to 55% off most machine types, and in exchange
you pay for one or three years whether you use the capacity or not. That is lock-in by contract,
the only kind with a date written on it, and the only kind a finance department will remind you
of.

And one more that is not technical: **what the team knows.** People who have learnt Cloud Run's
habits and Google's console are a real cost to move, and the cost is paid in a slower year, not
in a bill.

## Not all of it is bad

Every kind of lock-in is also a kind of value. Pub/Sub is locking because it does something well
that the team then does not build; a three-year commitment is locking because it is cheap. **The
question is never whether to accept lock-in, but which lock-in buys enough to be worth what
leaving would cost.** The rest of this lesson gives that sentence numbers.

| kind | what it buys | what undoing it costs |
|---|---|---|
| data gravity | storage someone else runs | egress, copy time, a cutover |
| proprietary interfaces | a service you did not build | rewriting every call site |
| platform configuration | behaviour without code | rewriting configuration, carefully |
| identity | one model of who may do what | redesigning permissions |
| commitments | a lower price | the remaining months of the term |
| skills | a team that moves fast here | a slower year somewhere else |
