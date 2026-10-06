---
title: Estimating likelihood and impact
version: 1
---

The formula **risk = likelihood × impact** is only as good as the two numbers put into it, and
neither comes from a table. Both are estimates, and the useful skill is knowing what moves them.

### What makes a threat more likely

Likelihood is the chance that a particular threat succeeds against a particular vulnerability in
a period, usually a year. Four questions move it:

| question | moves likelihood up | moves it down |
|---|---|---|
| **exposure:** who can reach the weakness? | anyone on the internet | only the office network, only one admin |
| **ease:** how hard is it to exploit? | a default password anyone can look up | a flaw that needs physical access and skill |
| **motivation:** is anybody looking? | automated scanners sweep the internet for it | it needs somebody to target the shop by name |
| **existing controls:** what already stands in the way? | none | MFA, a firewall rule, monitoring that would notice |

The first and last rows are the ones a defender controls. A shop cannot make criminals less
motivated, and it can make the portal unreachable from the internet and put a second factor on
it. That is why so much of this course is about exposure and controls: they are the levers.

History helps too. If the shop's laptops are lost or stolen about once every two years, that is
a likelihood with evidence behind it, and lesson 3 turns exactly that kind of number into money.

### What makes an impact larger

Impact starts with the triad: which property of which asset is lost. It becomes useful when it is
translated into what the business actually suffers:

| kind of impact | at the shop |
|---|---|
| **financial** | lost sales while the site is down, money stolen, the cost of the cleanup |
| **legal and regulatory** | a personal data breach reported to the ANPD, fines under the LGPD (lesson 17) |
| **reputational** | customers who stop buying after their data leaked |
| **operational** | staff who cannot work while the systems are restored |
| **safety** | rare at a bookshop; central in a hospital or a factory |

The same incident can score differently on each line. A day of downtime in February is mostly a
financial impact; the same day in the week before Christmas is a much larger one. A leak of the
price list has no impact; a leak of the customer list has a legal one, a reputational one and,
for the customers, a personal one.

**Impact is judged by the asset's owner, not by IT.** The person who runs finance knows what a
week without the payroll system costs; the person who runs IT knows how long it would take to
restore. A risk assessment needs both, which is why lesson 3 begins with asking people rather
than scanning machines.
