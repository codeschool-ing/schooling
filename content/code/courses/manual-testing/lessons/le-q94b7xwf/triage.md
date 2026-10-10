---
title: Triage
version: 1
---

The word comes from field hospitals, where it meant sorting the wounded by who needed help first,
and the borrowing is exact. **Triage decides what happens to each new report and in what order the
open ones get fixed.** It does not fix anything, and a triage meeting that turns into a debugging
session runs out of time with half the list undecided, which is the one outcome worse than a quick
wrong decision.

## Who is there, and what each brings

Three roles, whatever the team calls them:

- **the product owner**, for boxoffice the theatre's manager, who knows what each defect costs the
  business and therefore owns the priority;
- **a developer**, Rui, who knows roughly what each fix costs and which ones touch the same code;
- **the tester**, Ana, who knows the reports, can reproduce any of them on the spot and owns the
  severity.

Small teams triage in fifteen minutes twice a week; large ones have a rota and a queue. The size
changes nothing about the questions.

## The questions, in order

For each **new** report the meeting asks four things, and stops at the first one that ends it:

1. **Is it a defect?** Does the program contradict a requirement, or something the product plainly
   should do? If not, it is rejected, with the reason written on it.
2. **Is it already reported?** If so, it is a duplicate, linked to the original.
3. **Can we see it?** If the reproduction works, yes. If nobody can, the report goes back to its
   writer for more, and is not rejected yet.
4. **How bad, and how soon?** The severity is confirmed or corrected; the priority is set; somebody's
   name goes on it.

For the **open** reports the meeting asks only whether anything has changed: a deadline, a
customer complaint, a fix that turned out to be harder than thought. Priority moves; severity stays
unless the facts about the harm move.

## A triage on boxoffice 1.1

Release 1.1 is the current one. Seven defects are open, from the lessons that found them, and three
reports arrived this week. Here is the meeting's list as it ends:

| report | from | severity | decision |
|---|---|---|---|
| students are not charged half | lesson 10 | critical | P1, Rui, next build |
| a used order can be refunded, and its seats come back | lesson 5 | critical | P1, Rui, next build |
| a refund is accepted after the show has started | lesson 11 | major | P1, Rui, next build |
| the shows table is 760 pixels wide on a phone | lesson 7 | minor | P1: the season's campaign starts next week |
| a quantity that is not a whole number answers 500 with a traceback | lesson 15 | major | P2, this release |
| the tickets field has a placeholder and no label | lesson 14 | major | P2, this release |
| "cannot be payed", "cannot be useed" | lesson 11 | trivial | deferred to the next release |
| NEW: paying a paid order says "cannot be payed" | this week | | duplicate of the row above |
| NEW: a member booking five gets 15%, not 25% | this week | | rejected: R5 says the largest discount applies |
| NEW: the outbox shows every customer's e-mail | this week | | rejected: the outbox exists only in the test build |

Three decisions in it are worth reading closely, because each one is an argument somebody could
have lost.

**The refund after the show started is major and still P1.** It is a different rule from the used
refund (R6 says *before the show starts*), and the manager put it next to its neighbour because
Rui will be in the same few lines of code for both. Priority can follow the cost of the fix as well
as the cost of the defect, and that is a developer's contribution to the meeting.

**The traceback stayed at P2**, and Ana argued for P1: lesson 14's point that an error page showing
code hands information to a stranger. The manager weighed it against three defects that take money
from customers and kept the order, with a note on the report that it ships in 1.2 whatever else
slips. Ana's argument is on the record, which is what she needed: if the decision turns out wrong,
the report shows that the risk was raised and by whom.

**The misspelt messages are deferred, not closed.** They are real, they are trivial, and the one
line that fixes them is in the code Rui is about to change for the refunds, so they might be fixed
by accident. Deferring keeps them on the list until somebody checks.

## What the meeting writes down

Every decision goes into the report itself, not into the minutes of the meeting: the new state,
the priority, the name, and one line of reason for anything rejected, deferred or argued over.
Somebody reading the report in six months was not in the room, which is the same reader lesson 15
wrote the report for.
