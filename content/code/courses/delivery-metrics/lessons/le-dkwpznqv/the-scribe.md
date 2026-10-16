---
title: The person whose job is to write it down
version: 1
---

Of the four incident roles in lesson 13, the scribe is the one teams skip, because it looks like the least important: everybody else is doing something. It is the role whose absence is noticed latest and regretted most, the following week, when the postmortem tries to reconstruct what happened from memory and chat scrollback and gets the order wrong.

## What the scribe writes

**One line per event, with its time**, in the incident channel or a shared document, as it happens:

- **observations**: "17:44 Rafa finds 11 more duplicate charges";
- **decisions**, with who made them: "18:02 Bia decides to roll back D047";
- **actions**, when they start and end: "18:04 rollback started", "18:15 rollback complete";
- **changes of state**: severity raised, roles changed, status page updated.

Facts, not interpretations. "18:02 the retry logic is broken" is a guess written down as if it were known; "18:02 Rafa suspects BIL-218, the retry change" is a fact about what somebody thought, and it stays true even if the guess turns out to be wrong.

## Small rules that save a postmortem

- **One clock.** Every time in the same zone, written the same way. A timeline mixing UTC from the logs and local time from the chat is a timeline in which two events swap places.
- **Write it at the time, not after.** A line written ten minutes later has the wrong time on it, or no time, and a postmortem built on it will argue about ordering.
- **Tag the kind of event.** A short word at the start, *detect*, *declare*, *decide*, *restore*, *resolve*, lets a program, or a tired person, find the moments that matter. The next section uses exactly that.
- **Record what was tried and did not work.** A fix that failed is as important to the postmortem as the one that worked, and it is the first thing everybody forgets.

## Why it is a role and not a habit

Everybody agrees that somebody should take notes, and in the middle of an incident everybody assumes somebody else is. Naming a scribe makes it one person's job, and the job is real work: an incident with a good timeline gets a postmortem in an hour, and one without gets a postmortem that spends that hour arguing about what happened when. It is also **an excellent first role for somebody new to incidents**: they see the whole response, learn how decisions are made, and contribute something nobody else has time to.
