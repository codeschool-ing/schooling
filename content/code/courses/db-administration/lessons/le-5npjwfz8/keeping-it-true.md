---
title: Keeping it true
version: 1
---

A runbook that has never been run is a guess written in the imperative. It looks exactly like one
that works, and the difference shows at the worst moment: a command that changed its name in the
last upgrade, a path that belongs to another server, a verify that expects the wrong thing. The
previous sections' runbook had one of those on its first rehearsal, the expectation that `pg_wal`
would shrink, and only running it found it.

## Rehearse it, on a copy

**Run every runbook before it is needed**, the way this lesson ran the disk one: stage the problem
on a server that matters to nobody, follow the page as written, and fix every step where you had
to think. The copy can be a second virtual machine, or a cluster made beside the real one as lesson
20 does for an upgrade. A server built from lesson 23's repository is the cheapest copy of all,
because a script builds it. A rehearsal that needed a step the page did not have is
a rehearsal that paid for itself.

## A date and a name

The header carries **`Last rehearsed`** and **`Owner`**, and both earn their place. The date tells
the reader how much to trust the page: rehearsed last month on this version, or two years and a
major version ago. The owner is the person who updates it when the server changes, and a runbook
that belongs to everybody is updated by nobody. When the date gets old, the runbook is due a
rehearsal, which is a task you can put on a calendar.

## After every use

**The log of the night is the runbook's review.** Read it the next day beside the page and look
for three things: a step you skipped because it was wrong, a step you added because it was
missing, and a gap between two lines that was spent working something out. Each one is an edit,
committed with the date of the incident in the message.

Then read the last line. The runbook dealt with a slot that filled a disk, and the follow-up in
the log names the change that would stop the next one: **`max_slot_wal_keep_size`**, a limit on
how much WAL any slot may hold. Past it, the server gives up on the slot — its `wal_status` becomes
`lost` and the replica can no longer continue from it — instead of filling the disk. Whether a lost replica is
better than a full disk is a decision for the people who own both, and that is exactly why it is a
follow-up and not something done at three in the morning. The second follow-up, a monitoring check
on inactive slots, is a runbook step turning into an alert: check 3 run every minute by a machine
instead of once by a person after the damage.

## Where it lives

**Next to the configuration, and never only on the server it describes.** In lesson 23's
repository it is reviewed like code and versioned with the settings it mentions. But a runbook for
a server that is down has to be readable while that server is down. The copy people open is the
one on the Git server, or wherever your team keeps documents, and never the one in `/home` on
`db`.

The runbook is one of three kinds of document a database team keeps, and the other two belong
elsewhere. Running an incident and reviewing it afterwards is db-reliability lesson 22. The
documentation that lets somebody rebuild the server from its backups is db-reliability lesson 24.
