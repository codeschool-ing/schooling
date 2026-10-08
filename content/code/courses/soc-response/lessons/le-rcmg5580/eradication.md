---
title: Eradication: what was left, and the way in
version: 1
---

Lesson 13 left the company contained: `files` reaches only the backup, `203.0.113.66` is blocked, and bruno's
account is locked. None of that removed anything. **Eradication** removes two things, and a response that
does only one of them has to be done again:

1. **What was left behind.** An intruder who got in once usually makes sure of getting in again. On Thursday
   the timeline from lesson 12 shows it: a login with bruno's password, and then, at 03:05:22, a login with a
   **key**. Somebody added that key while they were in.
2. **The way in.** Thursday began with a guessed password on a server that accepted passwords from the whole
   internet. Remove the key and leave that, and the next guess works too.

Where things are left behind on a Linux server is a short list, and the audit of it is a defender's
checklist that does not depend on knowing what the intruder did:

| where | what to compare it against |
|---|---|
| `authorized_keys` in every home folder, and root's | an inventory of approved keys |
| the accounts in `/etc/passwd`, and who is in the `sudo` group | the staff list, and who should be an administrator |
| scheduled jobs: crontabs, systemd timers | what the server's owner says it runs |
| services that start at boot | the standard build for that server |
| recently changed files in system folders | the package manager's own record (`dpkg --verify`) |

The right-hand column is the hard part. An audit compares against **a record of what should be there**, and
a company without one cannot tell an intruder's key from a colleague's. That is why the next section starts
by writing the record.

**Every item is copied, hashed and logged before it is removed.** The key in bruno's file is evidence: its
fingerprint might appear on another victim's server, and lesson 8's sharing group would want it. Deleting it
in a hurry, with nothing kept, wins a minute and loses that.

In Thursday's record, the audit of both hosts found one item: a key in bruno's `authorized_keys` on `gw`
that bruno did not recognise when he was asked in person. It was copied into the incident folder with its
hash, and then removed.
