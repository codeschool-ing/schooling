---
title: Closing, and escalating
version: 1
---

Every alert ends one of two ways, and both are written down.

**Closing** needs a reason from a short, fixed list, because the reasons are what lesson 6's quality numbers
are counted from:

| reason | meaning | Monday's example |
|---|---|---|
| **false positive** | the rule matched something that is not what it describes | helena's typo |
| **benign true positive** | it is exactly what the rule describes, and it is allowed | an approved penetration test from a listed address |
| **duplicate** | already covered by an open alert or incident | Thursday's 03:05 alert, folded into the 02:33 one |

A closure note says *why* in a sentence a stranger would accept: "helena, from her usual address, one typo,
same pattern on other days" is a note; "FP" is not.

**Escalating** hands the alert to someone with more time, access or authority, and the note is what makes
the hand-off work. It carries what is known, what is not, and what was already done:

```localised
Escalation: possible account compromise, bruno, with data transfer
Known: 203.0.113.66 tried 19 accounts from 02:10 (local, 17 Sep), logged in as bruno
  at 02:33:07 by password, reached files at 02:35:40, and returned at 03:05:22
  by publickey. files sent 612,408,119 bytes to 203.0.113.200:443 at 02:41:12.
  bruno logged in normally from 203.0.113.17 at 08:35.
Not known: what was sent; whether bruno shared his password; how the key got there.
Done: nothing changed yet. Asked bruno's manager at 09:10 whether he works at night.
Priority: P1. Opened by ana, 09:12.
```

**Escalation is not failure**, and it is not a judgement on the analyst. A SOC where triage escalates
nothing has either a perfect environment or analysts who are afraid to, and only one of those exists.
