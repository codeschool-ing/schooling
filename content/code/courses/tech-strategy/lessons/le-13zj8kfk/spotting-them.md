---
title: Spotting them before they ship
version: 1
---

Nobody escalates a decision they do not recognise as a decision. The seat hold reached Mateus's
backlog as a performance fix, and it would have shipped as one if Davi had not read the ticket and
asked who loses a seat. **The skill is recognition**, and it can be practised, because these
decisions carry the same marks every time.

## The marks

Five signs, any one of which is enough to stop and ask:

1. **There is a number a user would feel.** A timeout, a cache lifetime, a retention period, a
   limit on how many tickets one buyer may hold. Numbers inside the system that nobody outside
   ever meets are engineering's; numbers that set how long somebody waits or what they are shown
   are not.
2. **The failure would be visible to a customer or a venue.** Ask what happens when the choice goes
   wrong. If the answer is "a slow query", it is technical. If the answer is "a buyer is shown a
   seat that is gone", it is not.
3. **Both options are technically sound.** When the engineers in the room agree that either would
   work and still disagree about which to pick, the disagreement is about who bears a cost, which
   is a question engineering cannot settle by being better at engineering.
4. **Somebody says "it depends what we want".** Every design review has heard it. The sentence is
   an admission that the decision turns on a goal, and the people who own the goal are not in the
   room.
5. **A default is about to be accepted.** A framework's timeout, a library's cache lifetime, a
   cloud service's retention setting. Nobody chose it, and it is still a choice.

The fifth is the one that caught Coreto. Catalogue's availability cache had a lifetime that came
from the caching library's default, and nobody had set it on purpose. It surfaced when a buyer
complained about being shown a seat that turned out to be sold, and the engineer who traced the
complaint found a decision nobody remembered taking, because nobody had.

## Coreto's list

Davi went through the backlogs of the seven teams with the five marks and came back with a short
list. Most items were plainly engineering's. A few were not:

| decision | how it was raised | the mark it carries | who should decide with engineering |
|---|---|---|---|
| seat-hold length | a fix for lock contention | a number a buyer feels | product, with the venues' view |
| availability cache lifetime | a library default | a default accepted | product |
| buyer data retention | a storage clean-up job | a failure a buyer and a regulator see | product and legal |
| checkout availability target | an alerting threshold | both options sound; "it depends what we want" | product and the CTO |
| offline scanning at the door | a sync strategy for Box Office | a failure a venue sees | product, Box Office and the venues |

The last column matters as much as the first. **The point of spotting a disguised decision is to
put the right people beside it**, and engineering stays in the room: it is the only party that knows
what each option costs to build and what it does under load.

## The opposite mistake

A team that learns this lesson badly starts sending everything to product. Which database index,
which queue library, how to split a module, which test framework: none of these carries any of the five marks. Asking product to weigh in on them wastes everybody's time, and it teaches product that engineering cannot decide its own work.

The marks are also a defence of engineering's autonomy. A decision without them is engineering's,
and saying so is easier once there is a clear rule for the ones that are not. **The test cuts both
ways**: it sends the seat hold to Júlia and keeps the index choice away from her.

| carries a mark | carries none |
|---|---|
| how long a seat is held | which index the holds table gets |
| how stale the seat map may be | which cache library stores it |
| how long buyer data is kept | which storage engine keeps it |
| what Box Office does when the network drops | how Box Office's local copy is serialised |

Each row on the right is the implementation of the row on the left, and that is the usual shape:
a product decision sits on top, and the engineering decisions beneath it are engineering's once the
top one is made.

## Where to look

Disguised decisions gather in a few places, and a lead can check them on purpose. Configuration
files, where defaults live. Pull requests whose description says "tune" or "adjust". Incident
reviews, where the fix proposed for the next time is often a new limit or timeout. And any design
document with a section called "trade-offs", because a trade-off with a user on one side of it is
the definition of this lesson's subject. Lesson 17 gives these decisions somewhere to be written
down once they are made.
