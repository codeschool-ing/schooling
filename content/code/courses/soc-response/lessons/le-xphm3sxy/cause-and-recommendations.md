---
title: Cause, and recommendations
version: 1
---

The **cause** section is lesson 15's contributing factors, rewritten for readers outside the team. The same blameless
rule holds, and it matters more here, because a report is read by people who may want somebody to blame:

> The intrusion was possible because four conditions held at once. The remote access server accepted passwords from
> any address on the internet, with no limit on attempts. Critical alerts reached a queue that nobody watched at
> night. The file server could send data to any address on the internet. And there was no record of which SSH keys
> should exist, so a key added during the night could not have been noticed.

No name appears in it, and none is needed: each condition is a property of the company's systems, and each one is
something the company can change.

**Recommendations** follow from the causes, one or more per cause, and the report says which cause each one answers.
They are prioritised, and the priority is explained by what each one would have changed on Thursday:

| priority | recommendation | answers | on Thursday it would have |
|---|---|---|---|
| 1 | page the person on call for critical alerts, at any hour | alerts nobody watched | cut the intruder's window from 7 hours to minutes |
| 2 | remote access by key only, in the standard build | passwords accepted from anywhere | stopped the first login |
| 3 | servers reach only the internet destinations they need | data could go anywhere | stopped the transfer |
| 4 | an inventory of SSH keys, audited daily | no record of which keys exist | flagged the new key by morning |

Each row points to lesson 15's action list, where the owner and the date are. **The report recommends; the
postmortem tracks.** A recommendation in a report with no action behind it is how the same report gets written again
a year later.
