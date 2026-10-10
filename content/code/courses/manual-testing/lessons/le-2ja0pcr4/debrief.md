---
title: The debrief
version: 1
---

A session is not finished when its time box runs out. It is finished after a **debrief**: a short
conversation, ten or fifteen minutes, between the tester and whoever leads the testing, held as soon
after the session as possible. Teams that skip it end up with session sheets nobody reads, and the
notes of a session are written in the tester's shorthand and make full sense for about a day.
**The debrief is where notes turn into decisions**: what gets reported, what gets added to a suite,
what the next session is.

## PROOF

Jonathan Bach, one of the two authors of session-based test management, gave the debrief a
checklist that spells its own name. Ana's debrief of the session in section 05, with the lead of the
theatre's testing, went through it like this.

**Past: what happened?** Sixty minutes on the life of an order, on 1.1. Nine of the twenty action and
state pairs, in the browser and with curl, and one question about time, set up in the session and
finished in the evening.

**Results: what was found?** Two new defects, each with its transcript: the refusal messages glue
`ed` onto the action, and a paid order is refunded after its show has started. One known defect seen
again, the refund of a used order, which needs nothing new. The lead's first question is whether
the two new ones are really two, and the answer is yes: one is a wording rule in every refusal, the
other is a missing rule in the one action that is not refused when it should be. They have different
causes, different fixes and different severities, so they are two reports.

**Obstacles: what got in the way?** The clock. With `BOXOFFICE_NOW` the application's time stands
still, and without it time only moves as fast as the real evening does; nothing lets a tester move
the clock while the application keeps its orders. **That is a testability problem, and it goes to
Rui as a request, not a defect**: a way to move the clock of a running application, or orders that
survive a restart, would turn the hour of waiting into a minute. An obstacle written down in a
debrief is often the cheapest improvement a team ever makes, because nobody else knew it was there.

**Outlook: what still needs doing?** Eleven pairs were not tried. The two opportunities on the sheet
are close to the charter and small: the seat count after a late refund, and booking at exactly 18:59
and 19:00. The lead turns all three into one new charter, *explore the order states and the closing
time with the remaining pairs and `BOXOFFICE_NOW` set around 19:00, to discover what else R4 and R6
leave open*, and puts it at the top of next week's list.

**Feelings: how does the tester feel about the area?** This one sounds soft and is not. Ana says
the order area feels shakier than its scripted cases made it look: all three of its defects appear at
the moment an order changes state, and two of them were found in an hour by somebody who was not
looking for them. That is evidence about likelihood, in the words of lesson 1, and it moves
risk C, a refund that should not happen, up the ranking. The scripted cases had said nothing of the
kind, because they passed.

## What a session leaves behind

A debrief ends with the session's output assigned to somebody:

| what | where it goes | who |
|---|---|---|
| two defect reports | the tracker, in the form lesson 15 teaches | Ana, today |
| a case for each defect | the regression suite of lesson 10, so the fixes are kept once made | Ana, when the reports are filed |
| the testability request | Rui's list, beside the defects | the lead |
| the new charter | the list of charters, at the top | the lead |
| the session sheet | the record of sessions per area | Ana |

The last row is what makes exploration reportable. **Sessions are counted per area the way cases
are counted per requirement**: four sessions on orders, one on sign-up, none on the Shows page this
release. A manager reading that list can see where exploration has been and where it has not, and
can disagree with it, which is what lesson 1 asked of every part of a plan. Lesson 19 puts numbers
like these into the one-page report leadership reads.
