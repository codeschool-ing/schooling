---
title: Defending a decision
version: 1
---

A record is proposed before it is accepted, usually in a pull request, and the review is where a
decision is defended. Reviewers ask the same few questions, and a good record has answered them before
anybody asks:

| the question | what answers it |
| --- | --- |
| "Why not the obvious alternative?" | the options considered, each with the reason it lost |
| "What does this cost?" | consequences that include the bad ones, with numbers where there are numbers |
| "What would make us change our minds?" | the conditions in the context: "at ten times today's traffic", "if the team grows past two" |
| "Is this reversible?" | how hard the decision is to undo, which decides how much argument it deserves |
| "Who else is affected?" | the teams, services or customers whose work changes |

This course has been a long rehearsal for the second row. Every pattern came with its price, measured in
the lab: the round trip of a synchronous call, the window of an eventually consistent copy, the latency
of a synchronous replica, the memory of a sidecar, the reservation that refused a customer for coffee
that was never sold. **A decision defended with a measurement is much harder to wave away** than one
defended with a preference, and much easier to revisit when the measurement changes.

The fourth row deserves its own sentence. Jeff Bezos's distinction between **one-way and two-way doors**
is the usual way to put it: a decision that can be reversed cheaply should be made quickly, by whoever is
closest to it, and a decision that cannot should be made slowly and written down with care. Most of the
records a team writes are about one-way doors, because those are the ones that will need explaining.
