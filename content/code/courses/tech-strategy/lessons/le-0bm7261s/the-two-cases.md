---
title: The two cases where it is worth it
version: 1
---

"Never rewrite anything" is the lesson people take from Spolsky, and it is too strong. The four
failures in the previous section each have a condition: they bite when the system is large, when the
old one keeps changing underneath, and when the switch is a single moment that cannot be undone.
**Take the conditions away and a rewrite becomes an ordinary piece of work.** Two situations take
them away.

## Case one: small enough for a quarter, behind a switch you can flip back

If the whole rewrite fits inside a quarter, most of the danger goes with the size. The old system
changes little in three months, so the target barely moves. The scope is small enough to estimate,
and small enough to notice when it starts to grow. And if the cutover is reversible — the old path
kept running behind a switch that sends traffic back to it within minutes — a mistake costs a morning
rather than an on-sale.

Coreto's PDF ticket generator is the example. Lesson 5 priced it at 120 hours of principal and 6 hours
a sprint of interest, and left it until a team was working in that code anyway. When that happens,
rewriting it whole is a reasonable form for the payment. It is one component with one job, turning a
confirmed order into a ticket file, and its output is easy to check: render the same order with both
generators and compare the files. A rewrite fits comfortably inside a quarter for one team, and a
setting can send ticket generation back to the old code if a venue's tickets come out wrong.

**Both halves of the condition matter.** Small without reversible is a big-bang cutover at a smaller
scale, and still a bad morning when it goes wrong. Reversible without small is a long rewrite with an
emergency exit: it still chases a moving target for eighteen months, and the exit only helps on the
last day.

## Case two: the ground is going away

Sometimes the foundation under a system is ending and cannot be moved piece by piece. A runtime
reaches the end of its support — Python 2 did, in 2020 — and the language the code is written in
stops receiving security fixes. A vendor closes the platform a component runs on. In each case doing
nothing has stopped being one of the options; the choice is between ways of moving.

**Even then, look for the incremental path first.** Most upgrades can be done one module at a time, and
lesson 7 is the method for moving a system while it keeps serving traffic. **A rewrite is justified
when that path does not exist**: when the old foundation and the new one cannot run side by side, so
there is nothing to move one piece at a time.

Coreto has a plausible candidate. Suppose the maintainers of the database version under the old
reporting replica announce the end of its security updates. The replica is the debt lesson 5 told the
team to leave alone, at a payback of 50 sprints. Once its database is ending, the payback stops being
the question, because the work is forced. A small rebuild of the reporting job on a supported
database, with the old replica left running until the new one gives the same reports, is the cheapest
way through. That is the "something outside the sheet" lesson 5 mentioned.

## Running the proposals through both cases

| question | the reservation rewrite | PDF generator | reporting replica, if its database loses support |
|---|---|---|---|
| fits inside a quarter? | no — eighteen months by its own estimate | yes | yes, the reporting job is small |
| cutover reversible? | no — one switch for the whole platform | yes — a setting sends tickets back | yes — the old replica runs until the new one matches |
| foundation going away? | no — nothing under it is ending | no | yes |
| verdict | do not rewrite | a rewrite is a reasonable form | a rewrite is forced |

Mateus's rewrite meets neither case. The module is nine years old, every team works in it, the
proposal needs a year and a half, and nothing beneath it is ending. What the module does have is one
path that hurts — the seat holds — and **a path can be moved without rewriting everything wired to
it**. Lesson 7 does exactly that with it.

## Two questions for any rewrite

Ask them in this order. Can the rewrite be finished within a quarter and undone in an afternoon? If
not, is the ground under the old system disappearing, with no way to move it piece by piece? A yes to
the first makes the rewrite a small project with a safety net. A yes to the second makes it the least
bad of the forced options. A no to both means the proposal is the kind Spolsky warned about, whatever
its slides say, and the next section puts a price on one.
