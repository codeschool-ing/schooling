---
title: Risk needs all three
version: 1
---

The most useful consequence of the chain in the previous section is the one people skip: **if
any link is missing, the risk from that path is zero.** That sounds obvious written down, and it
is ignored daily in practice, in both directions.

| situation | threat | vulnerability | asset | risk from this path |
|---|---|---|---|---|
| the portal has a default password and is on the internet | yes | yes | yes | real |
| the same portal is only reachable from inside the office | far fewer people | yes | yes | lower |
| the portal had a default password and nothing behind it | yes | yes | no | none |
| the portal has a strong unique password and MFA | yes | not this one | yes | none from this path |

The second row is where most security decisions live. Moving the portal behind the office network
did not fix the password. It reduced the number of people who could try it, which reduced the
**likelihood**. Lessons 4 and 5 build whole architectures out of that idea.

The third row is the one people forget when a scanner reports a vulnerability. A server with an
old, vulnerable program installed is not urgent if the server holds nothing, reaches nothing and
is about to be switched off. **A vulnerability without an asset behind it is a finding, not a
risk.** It still gets fixed, because servers have a way of acquiring assets later, but it does
not jump the queue.

### Likelihood and impact

Because risk depends on a threat actually happening and on how bad it would be, it is usually
expressed with two factors:

> **risk = likelihood × impact**

**Likelihood** is how probable it is that a threat exploits a vulnerability in a given period.
**Impact** is how much harm results if it does. The multiplication is not always literal; lesson
3 shows a qualitative version with words instead of numbers and a quantitative one with money.
What the formula says in every version is that **both factors matter**: a likely event with
trivial impact and an unlikely event with catastrophic impact can deserve the same attention.

ISO 31000, the general standard for risk management, defines risk more abstractly as "the effect
of uncertainty on objectives". The two definitions do not compete. The ISO one explains why risk
exists at all: you do not know what will happen. The likelihood-and-impact version is how you
measure it in practice. NIST's guide to risk assessment, SP 800-30, works with the second.
