---
title: The trade-offs, and who decides
version: 1
---

NIST SP 800-61 names the questions a containment strategy has to answer, and they are a better checklist
than any single rule:

- How much **damage**, or **theft**, is still possible if nothing is done?
- What **evidence** has to be kept, and does this action destroy any of it?
- Which **service** stops, and for whom?
- How much **time and effort** does the action take?
- How **effective** is it: does it close the way in, or one of several?
- How long is it meant to last: an **emergency** measure for hours, a **temporary** one for days, or
  **permanent**?

Nobody answers those alone. The analysts **propose**: they know what the action does technically. The
incident lead **decides**, within the authority the plan gives that role. And a decision that stops part of the
business, such as taking the file server off the network for a day, goes to the **executive sponsor**,
because that is a business decision with a technical description. Lesson 11 wrote those roles down so this
would not have to be negotiated at nine in the morning with data leaving.

There is one more option on the table, and it is a real one: **watch before acting.** Some teams leave an
intruder in place for a while to learn what they are after and how many ways in they have. It is a decision
with a large cost, more damage while you watch, and it belongs to the lead together with legal, never to an
analyst who thinks it would be interesting. For Thursday there is nothing to gain: the data has already
left, the way in is known, and every hour of waiting is an hour in which bruno's account still works.

Each decision goes into the decision log, in the same form. For Thursday morning:

| time | action | proposed | decided | why | undone by |
|---|---|---|---|---|---|
| 09:31 | volatile state of `gw` and `files` collected and hashed | ana | ana | before any change | (nothing to undo) |
| 09:38 | egress rule on `fw`: `files` to the backup only | ana | ana | data left to `203.0.113.200` | rule `INC-2026-014 files egress`, by handle |
| 09:40 | block `203.0.113.66` on `fw` | diego | ana | cheap; slows the obvious retry | rule `INC-2026-014 source`, by handle |
| 09:45 | bruno's account locked on `gw` and `files`; sessions ended | ana | managing partner | stolen password and an added key | new credentials, issued to bruno in person |

The managing partner signs the last line because it stops a member of staff from working, and because
bruno has to be told in person, by somebody other than an investigator, which is lesson 19. The two
firewall rules are ana's to decide: they break nothing the business uses. **The log does not need to be
elaborate; it needs to exist at the time**, written as things happen. Reconstructed afterwards, from memory,
it is the first thing a lawyer or a regulator learns to distrust.
