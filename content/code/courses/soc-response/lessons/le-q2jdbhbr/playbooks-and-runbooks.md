---
title: Playbooks and runbooks
version: 1
---

Two kinds of written procedure support the plan, and the words are used loosely enough to cause confusion.

A **playbook** covers **one type of incident**, from detection to closure: what to check, what to decide,
who to involve. Lesson 5's automated playbook was a narrow, machine-run slice of one. A **runbook** covers
**one technical task**, step by step, whatever the incident: how to isolate a host on this network, how to
image a disk with this tool, how to reset a password in this directory. Playbooks call runbooks.

A playbook for the incident type that fits Thursday, *compromised account with remote access*, in outline:

| phase | the playbook says |
|---|---|
| identify | confirm with the account's owner, by a channel other than that account; list every host and every session the account touched |
| contain | block the source address; revoke the account's sessions and keys; disable it if the owner cannot be reached (runbook: disable an account) |
| preserve | copy the logs of every touched host before changing anything; image the hosts if data may have left (lesson 16's runbook) |
| eradicate | remove what the intruder added: keys, accounts, scheduled jobs (runbook: audit `authorized_keys`) |
| recover | new password, new keys, multi-factor authentication; monitor the account closely for two weeks |
| notify | if personal data may have been accessed, inform the DPO and legal at once (lesson 21) |

**A playbook is only as good as the runbooks behind it**, and a runbook is only good if it has been run. The
command that isolates a server, written in a document nobody tested, fails at the worst moment because
the interface was renamed last year. Test runbooks when they are written, and again when the system
changes.
