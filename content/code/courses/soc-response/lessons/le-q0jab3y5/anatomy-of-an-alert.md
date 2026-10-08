---
title: What an alert has to carry
version: 1
---

A dashboard is read when somebody chooses to look. An **alert** interrupts. That is a cost paid in
somebody's attention, and an alert has to earn it by carrying enough for a person to act without opening
five other screens first.

| an alert carries | in lesson 4's v2 alert |
|---|---|
| **what fired**, by name and rule id | *Login accepted from an address that tried many accounts*, `5e7a1c40-…` |
| **why it matters**, in one sentence | a guessing run was followed by a successful login |
| **the key fields** | the address, the account that got in, the host, the times in UTC |
| **severity** | critical: a login worked, so somebody may be inside |
| **the evidence**, linked | the event ids the rule matched, so the analyst can open them |
| **what to do first** | a link to the playbook or runbook for this alert |
| **who owns it** | the queue or person it was routed to |

Severity deserves care, because it is the field everybody sorts by. It is a statement about **what the
alert means if it is true**, not about how sure the rule is. A rule that is right half the time about
something critical produces critical alerts half of which are false, and lesson 7 is about telling them
apart. A team that lowers a rule's severity because it is noisy has hidden a problem in the one field
meant to show it; the honest fix is in the rule.

And an alert without an owner is an alert nobody is responsible for reading. Routing is part of the alert,
not something that happens to it later.
