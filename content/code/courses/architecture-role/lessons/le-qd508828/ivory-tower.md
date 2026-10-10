---
title: The ivory tower, and the gatekeeper at its door
version: 1
---

**The ivory-tower architect decides far from the people who live with the decisions.** The
decisions may even be good ones. They arrive finished, without the teams having been asked and
without the architect having seen what the teams see, so they are either quietly ignored or followed
straight into a wall. The PowerPoint architect is separated from the code; the ivory tower is
separated from the people. They often travel together, but a tower can sit on top of perfectly
accurate diagrams.

## What it looks like

Imagine Renata issuing a standard by memo: *from 1 March, every call between services goes through
the message broker*. She has good reasons. Synchronous calls between services had caused two
cascading failures that year, and lesson 1 showed how much the connector changes the way a system
fails. She writes the memo alone, announces it at the all-hands, and publishes it on the wiki.

Diego Araújo, the Driver app's tech lead, learns about it from the memo. The app's login asks the
backend whether a driver's documents are valid, and it needs the answer in under two seconds on a
3G connection somewhere on a highway in Mato Grosso. A broker in the middle of that call adds a hop,
a second failure mode and no benefit. Diego files an exception. So does Payments, for the bank's
callback, and Pricing, for quotes. **Within two months, six of the seven teams have exceptions.** A
standard that six teams in seven are excused from is not a standard; lesson 9 would call it a
guideline nobody follows, with paperwork attached.

The symptoms:

- **Standards arrive without a reason or an owner the teams can argue with** (lesson 9).
- **Requirements are assumed rather than gathered.** The tower knows the system as it was
  described to it, not as it is used; nobody asked Diego about 3G on a highway (lesson 7).
- **The architecture forum is a broadcast.** The architect presents, questions are taken, and
  nothing that was said in the room changes the decision (lesson 10).
- **Teams stop mentioning their workarounds.** The official architecture and the real one drift
  apart, and the second one is invisible from the tower.

## Why it happens

**Formal authority is used where earned authority was needed.** Lesson 3 separated the two: a title
can make people comply for a while, and only a track record makes them agree. The memo leans entirely
on the first.

**Deciding alone is faster, once.** Asking seven teams takes a fortnight; writing a memo takes an
afternoon. The fortnight saved is then spent several times over in exceptions, workarounds and the
conversation that should have happened first.

**The architect sits with the executives and not with the teams.** Nothing in the tower's week puts
it next to an on-call rota, a support ticket or a driver's phone.

**The architect believes the value of the role is the answer.** Lesson 11 argued that it is the
quality of the decision process: asking before answering, and helping a team decide rather than
deciding for it.

## What it costs

Decisions get ignored, so the company ends up with **two architectures, the declared one and the
real one**, and plans against the first. Bad decisions are not caught, because the person who knew
the constraint (Diego, with the 3G login) was never asked. And the teams learn that the forum is
theatre, which makes the next good decision harder to get adopted than the last bad one.

## The alternative

- **Run the decision through the advice process** (lesson 3). The memo becomes a proposal sent to
  the forum and to the tech leads, with a date by which advice is due. Diego's constraint arrives
  before the decision, and the standard comes out as "asynchronous by default between back-end
  services, with these named cases for synchronous calls", which the teams can live with.
- **Go to where the decisions land.** A week a quarter inside a team, pairing on its code (lesson
  15), reading its incident reports, sitting in on its planning. The tower cannot see a highway in
  Mato Grosso; a pairing session with the Driver team can.
- **Write the reason down and welcome the exception.** Lesson 9's exception process, with an expiry
  date, turns a disagreement into information instead of a quiet workaround.

## The gatekeeper: the tower moved to the door

The gatekeeper is the opposite distance with the same result. **The gatekeeper architect is very
close to the teams and insists on approving everything they do**: every design document, every new
library, every pull request that touches two services. Nothing happens without her signature.

The symptom is a queue. Suppose 25 designs reach Renata's desk in a month and each waits four
working days for her; that is **100 working days of waiting a month**, spread across seven teams,
and none of it shows on any dashboard. Teams start designing to pass review rather than to solve the
problem, and they split their work in odd ways to stay under whatever the review threshold is. The
cause is usually understandable — an incident that a review would have caught, or a fear of losing
control of the whole as the company grows — and the reaction is a gate in front of everything
instead of in front of what matters.

The alternative uses what lesson 16 built. **The decision-rights table says which decisions are the
architect's**, and they are two rows out of seven. Standards that can be checked by a machine are
checked by one (lesson 9). Design review is kept for what crosses team boundaries (lesson 11), and
everything else is left to the teams, who know their own code better than any reviewer could.

The ivory tower and the gatekeeper look like opposites, one too far and one too close. What they
share is the belief that the architect's judgement has to be applied to each decision personally,
instead of being built into the way the teams decide.
