---
title: Friday morning, and the release decision
version: 1
---

**On Friday morning Lia reports the exit criteria one by one, met or not met, and Joana decides whether to release.**
That division is the whole point of the exercise: the tester provides the evidence, the person accountable for the
product makes the call.

## The report against the criteria

| criterion | status |
|---|---|
| every area got its planned hours, or the shortfall is written down | **met**, with a shortfall: after Thursday's suspension, the seat map got 20 minutes instead of 2 hours and the report 30 minutes instead of 1 hour |
| every agreed acceptance test passes | **met**: ten scenarios, all green, lesson 17's run |
| no open high or critical defect in prices, orders or refunds | **not met**: the 9:30 session is charged the evening price |
| every open defect has an owner and a decision | **met**, apart from the 9:30 defect, which is waiting for this meeting |
| the summary lists what was tested lightly and what was not | **met**: lesson 20's four-part summary, updated |

One criterion is not met, and the report says so plainly. Lia does not soften it, and she does not round it up because
the other four are green.

## The decision

The 9:30 defect had been waiting on a question since lesson 17's three amigos: should the program accept *9:30*, or
should the schedule always say *09:30*? Célia's answer arrived on Thursday: the schedule system lets her type the time
either way, and she typed *9:30* once, for the first morning session. From now on she can type *09:30*.

Joana's decision, written in the summary beside the criterion:

> **Release on Friday.** The 9:30 defect is accepted for this release, with a workaround: morning sessions are typed
> with a leading zero, and Célia has checked the current schedule. Rafael fixes the comparison in the next sprint, with
> lesson 19's relations check added to the automated checks so the defect cannot return unnoticed.

That is a legitimate outcome. An exit criterion not met does not automatically mean *do not release*. It means *the
person who decides must decide knowingly*, and record why. What would not be legitimate is releasing with the criterion
quietly marked as met, or the 9:30 defect quietly downgraded to *medium* so the table turns green.

## What the tester owns, and what she does not

Lia owns the truth of the report: that each status is accurate, that the evidence exists, that the gaps are stated. She
does not own the release. If Joana had decided to release with a defect Lia thought dangerous, Lia's part would be to
say so clearly, in writing, with her reasons, and then to accept the decision of the person accountable for it. That is
lesson 5's argument again: the tester is not the guardian of *you cannot ship*, but the person who makes sure nobody
ships without knowing what they are shipping.

The next cycle starts on Monday, with its own entry criteria. One of them is new: *the relations check passes*, which it
will do only once Rafael's fix is in the build.
