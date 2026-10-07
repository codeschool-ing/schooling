---
title: Getting from comments to a decision
version: 1
---

**Most proposals do not fail by being rejected. They fail by never being decided.** The document
goes out, four people comment on the formatting, nobody with authority says anything, and three
weeks later the author is not sure whether silence means yes, no or "not read yet". All three are
common, and they lead to opposite next steps.

## Silence is not consent

**Never treat no reply as approval.** The person who did not reply did not read it, or read it and
disagreed without having time to say so, or assumed somebody else would object. When the change
ships and breaks something of theirs, "it was in the document for three weeks" is accurate and
does not help.

What works is naming the people and their roles at the top of the document, before it is sent:

| role | who | what they do |
|---|---|---|
| **decides** | Renata | approves or rejects, by the date |
| **must review** | Bruna, Henrique, platform team | their comments must be answered before the decision |
| consulted | support, data team | invited to comment; no answer needed from them |
| informed | all engineering | told of the outcome |

The structure is the same as the RACI and DACI charts that project managers use. **Whatever the
acronym, each person knows whether their silence matters.** A *must review* who
has not replied by the halfway point gets a direct message, not another broadcast.

## A date, and a meeting only to close

Every review has a closing date written in the document. Without one, the review lasts as long as
the most hesitant reviewer wants. Two weeks suits most proposals; an urgent one can say three days
if it says why.

When comments stop converging (a thread of thirty replies between two people is the sign), **move
the disagreement to a call and write the outcome back into the document.** The call is not where
the decision is made; it is where a disagreement gets understood quickly enough for the decider to
make it.

Lívia ends most reviews with one thirty-minute meeting, scheduled when the document goes out. The
agenda is the list of unresolved comments, nothing else. If none are left, the meeting is cancelled
and the decider writes "approved" in the document.

## Answer every comment, visibly

Each comment ends in one of three states: **changed** (the document now says something different),
**declined with a reason**, or **open** (recorded as an open question with an owner). A reviewer
whose comment disappeared without an answer stops reviewing. A reviewer who sees "declined, because
the replica lag would break the stock count; see the alternatives section" may still disagree, and
knows they were heard.

## Write the decision where the proposal is

The decision goes at the top of the document, with the date, the decider and the conditions:

> **Decision, 19 March: approved** by Renata, with Caio's agreement on the cost. Condition: the
> replica's lag is measured for two weeks before the route planner is switched over. Open question
> Q3 (who owns the replica's alerts) goes to the platform team, answer due 2 April.

Two lines, and the next person who opens the document a year later knows what happened without
reading forty comments.
