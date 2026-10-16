---
title: Handing over, and knowing when it is over
version: 1
---

Most incidents end within an hour or two. Some do not, and the last part of running an incident is knowing how to keep it going across people and hours, and how to end it cleanly.

## Handing over command

Nobody makes good decisions in the fifth hour of an incident, and nobody should be expected to. **For a long incident, the incident commander hands over**, typically every few hours, and the handover is itself a small procedure:

1. **The outgoing IC writes a summary in the channel**: what is known, what has been done, what is in progress, what the next decision is and when it is due.
2. **The incoming IC reads it, asks questions, and says out loud that they have command.** "I have command" removes any doubt about who decides.
3. **The scribe records the handover**, with its time, like any other event.
4. **The outgoing IC actually leaves.** Staying "to help" splits the command again.

The same applies to the technical lead and the scribe. A rota for a long incident is drawn up early, while people are still fresh enough to plan it, rather than when everybody is exhausted.

## When it is over

An incident has two ends, and the timeline of 30 September records both: **restored** at 18:15, when no more duplicate charges were happening, and **resolved** at 21:10, when every duplicate had been refunded.

It is reasonable to downgrade an incident once it is restored. A SEV1 that is no longer harming anybody can become a SEV3 while the cleanup runs in working hours, and people who are not needed for the cleanup can stand down. It is a mistake to **close** it before it is resolved, because closing tells everybody, support included, that there is nothing left to say to the people affected.

## Closing properly

When the incident is resolved, the incident commander does four things before closing it:

- **posts a final update** to every audience, saying what happened in users' terms, that it is over, and what happens next for anybody affected;
- **makes sure the evidence is kept**: logs, graphs, the channel, the timeline, before retention policies delete them;
- **books the postmortem**, for a time within a few working days, while memories are fresh, as Caio's final update on 30 September did for Friday 2 October;
- **opens a ticket for anything left over** that is not urgent: the proper fix for `BIL-218`, in this case, rather than the rollback.

That last ticket is the bridge to lesson 15. The rollback mitigated the incident; the fix will come from understanding it, and understanding is what the postmortem is for.
