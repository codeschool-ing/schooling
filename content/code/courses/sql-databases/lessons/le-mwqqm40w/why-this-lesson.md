---
title: Why a lesson on an engine you may never install
version: 1
---

Lesson 12 compared four engines and closed by saying there was a fifth that did not belong in the
comparison. This is it, and the reason it gets a lesson of its own is not that it is better or
worse. It is that **Oracle Database is expensive in a particular way, and that way changes the
shape of the systems built on it.**

Everything in lessons 1 to 11 applies to it. It is a relational database with keys, joins,
transactions, indexes and a planner, and the habits this course has built are the right habits
there. What is different is the world around it.

## Where it actually is

Not on anybody's laptop, and not behind most websites. Oracle is where large organisations keep
the records they cannot lose:

- banks and insurers — core banking, policies, claims
- telephone companies — billing and provisioning
- governments — tax, registries, health systems
- large retailers and manufacturers, usually underneath an ERP such as SAP or Oracle's own

The common thread is a system that was bought or built between fifteen and thirty years ago,
holds data with legal weight, and has been working. Nobody in those organisations is choosing
Oracle this year. They chose it once, and everything since has been built next to that decision.

**So the skill this lesson teaches is not how to run Oracle.** A large organisation has database
administrators, and they will not be you. The skill is being the developer who writes correct,
reasonable SQL against a system whose rules are not the ones the internet assumes — and who can
tell which of the odd things around it are technical decisions and which are consequences of a
contract.

## A note about this lesson, which matters

Every other lesson in this course ran its examples on a server and showed you what came back. The
transcripts in lessons 9 to 12 are real: a PostgreSQL, a MySQL, a MariaDB and a SQLite, each
loaded with the shop from lesson 1, with their output pasted in unedited.

**This lesson has no Oracle to run.** There is no free, redistributable Oracle Database that can
sit in the same place those four sat, and inventing a terminal session would be worse than
useless: it would look exactly like the others and be a fabrication.

So this lesson **describes** rather than captures. Where it says what Oracle prints, that is a
description of documented behaviour and it says so in the sentence. There is no code block in
this lesson claiming to be a session, and where SQL appears it is SQL to write rather than a
transcript of it being run. Checking any of it against a real instance is worth doing, and is
the sort of thing to do on your first week somewhere that has one.

## The order

The licence comes second, before the SQL, and that ordering is the argument of the lesson. Most
of what surprises people about an Oracle system — where the logic lives, why there is no
reporting replica, why nobody has looked at the performance reports — follows from what the
contract costs rather than from what the engine does.

Then the dialect, which has real traps; PL/SQL, which is where a corporate system's logic
usually is; how reads and transactions differ; how it is operated and by whom; and what you can
actually do as a developer who does not hold the keys.
