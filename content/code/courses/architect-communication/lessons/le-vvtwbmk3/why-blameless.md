---
title: Why blameless, and what it does not mean
version: 1
---

**A postmortem that looks for somebody to blame finds one, and learns nothing else, because everybody
else stops telling the truth.** A blameless postmortem assumes that the people involved did what made
sense to them with what they knew at the time, and asks why it made sense. The answers are where the
system's weaknesses are.

## The first draft

The first notes on the 6 March incident, written by an engineer late on Friday night, said: "Root
cause: logistics ran a backfill during peak without checking." It was accurate as far as it went. It
also made Paulo, who had started the job, the cause; and lesson 9 showed what that sentence did to the
relationship between two teams for months afterwards.

Paulo had followed the runbook. The runbook said to run the backfill "when delivery zones change". Zones
had changed that afternoon. Nothing in the runbook, the job, the database or the calendar said that
Friday at 19:05 was a bad time, and nothing stopped the job opening as many connections as it wanted.
**Any engineer at Marola, given that runbook on that afternoon, could have done the same.** That is the
sentence a blameless review is looking for.

## Where the idea comes from

John Allspaw, then running operations at Etsy, wrote the post that made the practice widely known in
2012, *Blameless PostMortems and a Just Culture*. The argument he made, drawing on safety research in
aviation and healthcare, is practical rather than kind: an engineer who expects to be punished for a
mistake will give an account that protects them, and the organisation loses the detail it needs. An
engineer who expects to be asked "what did you see, and why did it make sense?" gives the detail.

Sidney Dekker, whose work on human error underpins much of this, calls the principle *local
rationality*: people's actions make sense from where they stood, with what they could see. **The job of
the review is to reconstruct where they stood.**

## What blameless does not mean

- **Not that nobody is accountable.** Accountability moves from "who did it" to "who will change what,
  by when", and the actions at the end have names on them.
- **Not that anything goes.** Deliberate sabotage, or ignoring a rule out of contempt, is not a systems
  problem. These cases are rare, and they are handled as conduct, outside the postmortem.
- **Not avoiding names entirely.** The timeline says Paulo started the job at 19:05, because he did.
  What it does not do is stop there as if that explained anything.

::: track tech-lead
`delivery-metrics` lesson 15 covered blameless postmortems from the tech lead's side: action items and
making them get done. This lesson concentrates on the writing and the meeting, which is where blame
gets in or is kept out.
:::

::: track *
The rest of this lesson is the writing and the meeting, which is where blame gets in or is kept out.
:::
