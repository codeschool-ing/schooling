---
title: Why it got built anyway
version: 1
---

The easy explanation for the portal is that somebody made a bad call. **It does not survive the
facts**: several capable engineers worked on it for months, it was approved, and it was shown to the
whole company. A mistake that many people make together has a cause in how the work was chosen, and
the same cause will produce the next portal unless somebody names it.

The autopsy found three causes, and they reinforce each other.

## Building is visible; not building is not

A built tool has a demo, screenshots, a launch post and a line in somebody's review. A short
investigation that ends in "the teams with pipelines do not need this" has none of those. It is
the better outcome and it looks like nothing happened.

That asymmetry pulls every team towards building, and it is nobody's character flaw. The Platform
team of the time was judged by what it delivered, and a portal is a delivery. **Finding out that a
tool is unnecessary is work too, and an organisation that does not count it as work will keep
getting tools instead.** Helena Prates, the CTO, drew that conclusion from the autopsy: from then on,
an investigation that ended a proposal was presented at the engineering review like any launch.

## Nobody asked the people who would use it

The portal's requirements came from Platform's chat channel, which is where requests arrived.
"Which version is in production?" "Can you roll back the ticket-PDF service?" "Can you approve this
deploy?" Each request was real, and together they described a tool that would answer them.

The flaw is in who was asking. **The channel only heard from the teams that needed Platform's help
to deploy**, which were the teams without pipelines. The 38 teams whose pipelines deployed on every
merge never asked anything, so they were invisible in the requirements. Platform built for its
loudest users and launched to its silent ones.

Asking would have been cheap. A conversation with each of the six other team leads, framed as "how do
you deploy today and what hurts about it?", would have shown in an afternoon that most teams had
nothing to fix in deploying. `architect-communication` lesson 6 is about that kind of listening —
finding the need behind a request — and lesson 7 of the same course argues for diagnosing before
proposing a solution, which is exactly the step the portal skipped.

## It solved the builders' problem

Look at what the portal removed. The chat requests stopped interrupting Platform, the questions
about versions answered themselves, and approvals left a record. **Every one of those benefits
landed on the Platform team.** For the teams without pipelines the portal was a real gain; for the
others, it was a browser tab added to a deploy that had needed none.

The test is short to state: whose week gets easier? A tool that mostly makes its builders' week easier is an internal efficiency project, and it may still be worth doing. It should then be sized and justified as one, against the hours of interruption it saves Platform, rather than launched as a product for everybody.

| the question | the portal's answer | the answer that would have stopped it |
|---|---|---|
| who asked for it? | requests in Platform's channel | the teams who would change how they work |
| what do they do today? | not asked | 38 of 41 deploy on merge already |
| whose week gets easier? | Platform's | the users' |
| what would make us stop? | nothing written down | a date and a level of use |

## And nothing said when to stop

The project plan had a launch date. It had no point at which anybody would ask whether to continue.
Every month the portal was nearer to finished, the hours already spent grew, and stopping felt more
wasteful than finishing. That is the sunk cost from the autopsy working in the other direction: it
kept the project alive before launch, as it would have kept the portal alive after it if Rafaela had
let the R$ 165,000 into the decision.

**A project with no decision date is decided by momentum**, and momentum always says "nearly done".
The next section is about the four steps that would have stopped the portal while it was still a proposal. Lesson 18 gives this risk the name product people use for it: the risk that nobody wants what is being built.
