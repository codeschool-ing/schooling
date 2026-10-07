---
title: The technical proposal
version: 1
---

**A technical proposal exists to let reviewers find the flaw before the code does.** It is where a
design is compared with its alternatives, in enough detail that somebody who disagrees can say
exactly where. Google calls the same document a design doc, and others call it a technical
specification; the names vary and the parts do not.

The one-pager in the last section asked Renata and Caio whether to spend the money. The proposal
behind it asks Bruna, Henrique and the platform team whether this is the right way to spend it.
Different readers, different decision, so a different document.

## The parts, and what each one is for

| part | what it answers | what goes wrong without it |
|---|---|---|
| context and goals | why now, and what success looks like, measurably | reviewers judge the design against goals of their own |
| **non-goals** | what this deliberately does not try to do | every reviewer adds their favourite problem to the scope |
| the design | what changes, with a diagram of the parts that move | reviewers argue about a design they each imagined differently |
| **alternatives considered** | what else was weighed, and why it lost | the first comment is "why not just…?", fifty times |
| cost and risk | engineer time, money, and what could break | the decider approves a number nobody wrote down |
| rollout and rollback | how it is switched on, and how it is switched off | the plan only works if nothing goes wrong |
| open questions | what the author does not know yet | reviewers find the gaps and read them as carelessness |

Two of these deserve more than a line.

## Non-goals keep the scope still

Lívia's proposal lists three non-goals: it does not move checkout off PostgreSQL, it does not
change how orders are stored, and it does not give any other service access to the replica in
this phase. Each one is a sentence that pre-empts a long comment thread. The third was the most
useful: two other teams wanted replica access, and the non-goal let the review say "yes, later, in
a separate proposal" instead of absorbing their requirements.

**A non-goal is not a thing that is unimportant.** It is a thing that is important and is not
being decided here.

## Alternatives considered is where trust is earned

A proposal with only one option reads as a decision that has already been made, and reviewers
respond by attacking it. A proposal that shows two or three alternatives, each with an honest
reason it lost, reads as a choice the author worked through, and reviewers respond by checking the
reasoning.

Lívia's has four, and the first is always the same:

1. **Do nothing.** The baseline every other option is measured against. It costs nothing now, and
   the failures grow with order volume.
2. **A larger database server.** One day of work and R$ 9,000 a month more. It moves the limit
   rather than removing the competition, so the problem returns as volume grows.
3. **Connection pooling in front of the database.** Cheap and worth doing anyway, but it rations
   connections between the route planner and checkout rather than separating them; on a bad Friday
   one of them still waits.
4. **A read replica for the route planner** (the proposal). Six engineer-weeks and R$ 4,000 a
   month, and it removes the route planner's reads from the primary entirely.

Note what option 3 says: *worth doing anyway*. **An alternative that loses can still be partly
right**, and saying so is what makes reviewers believe the comparison was fair.

## Write it to be reviewed

Number the open questions so comments can refer to them ("on Q2: …"). Put the diagram before the
prose that explains it. Date the document and give it a status at the top (*draft*, *in review*,
*approved*). And keep it short enough to be read: a proposal over ten pages is usually two
proposals, or a proposal with its research notes still attached.
