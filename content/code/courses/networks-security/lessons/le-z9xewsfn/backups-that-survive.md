---
title: Backups the attacker cannot reach
version: 1
---

Ransomware's leverage is simple: the files are encrypted and the only copy of the key is the
attacker's. **A backup that can be restored removes the leverage**, and modern ransomware knows it,
so it looks for backups first and encrypts or deletes them before announcing itself. A backup that
the infected machines can write to is a backup the ransomware can destroy.

The network design that follows is about **direction**:

| design | who starts the connection | can an infected client damage the backup? |
|---|---|---|
| clients push to a shared folder on the backup server | the client | yes: whatever the client can write, the software on it can overwrite |
| the backup server pulls from the clients | the backup server | not through the network: nothing inside may open a connection to it |
| the backup is also copied offline or to immutable storage | a separate process, on a schedule | no: the copy cannot be changed for a set period, by anybody |

In the terms of lesson 4's matrix, the backup server has a **row** (it may reach the machines it backs
up, on the one port its agent uses) and an **empty column** (nothing may start a conversation with it,
except administration from the management segment). That is the same shape as the DMZ's, drawn for
the opposite reason: there the empty cells protect the inside from the DMZ, here they protect the
backup from the inside.

Two practices the network cannot supply and a defender still owns:

- restore tests, on a schedule, because a backup nobody has restored from is a hope rather than a
  backup;
- credentials the domain does not know: if the backup system's administrator account is the same
  one the rest of the company uses, the attacker who took the rest of the company takes that too.

## What the network contributes, in one list

Put together, this lesson's network controls turn each stage of the pattern into a place where the
attack can stop:

- at delivery, the mail gateway and sandboxing, the NGFW features of lesson 2;
- at the first click, protective DNS;
- against spreading, host firewalls;
- at the first sign, a quarantine rule;
- at the end, backups that no infected machine can reach.

None of them replaces the person who reports a
suspicious message early; each of them buys time for that person to matter.
