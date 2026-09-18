---
title: Who runs it, and with what
version: 1
---

Lesson 12's section on operations asked four questions — where the second copy lives, what a backup
means, what an upgrade costs, and who is on call. Oracle answers all four, and the answer to the
fourth is different in kind: **there is a person whose job this is, and it is not you.**

## The database administrator is a role, not a rota

On a small PostgreSQL system the developers operate the database between them. A corporate Oracle
system has database administrators: people who hold the credentials, apply the patches, run the
backups, size the undo, and decide what gets installed.

This changes how a developer works, and the change is not a restriction to route around:

- **You will not have `SYSDBA`**, and should not. Most of what you need is a grant.
- **Schema changes go through a process.** A migration is a script somebody reviews and runs, which
  is lesson 11's discipline with a person attached to it.
- **The interesting diagnostics may need a licence or a privilege**, as the licence section said,
  so the DBA is the right first question rather than the obstacle.

The productive posture is to arrive with a specific request and the evidence for it. "This
statement, this plan, these row counts, and I think it needs an index on this column" is a
conversation. "The database is slow" is not.

## The tools

**SQL\*Plus** is the command-line client, and it is the `psql` of this world with a much older
sensibility: it has its own commands for formatting output, it does not commit for you, and it is
present on every Oracle server ever installed. Knowing enough of it to connect, run a statement and
spool the output to a file is worth an hour.

**SQL Developer** is Oracle's free graphical client, and **TOAD** is the long-established commercial
one. In a corporate environment you will be handed one of them.

**RMAN** is the backup tool. It does the physical backups, the incrementals and the restores, and
lesson 12's rule applies to it unchanged: a backup nobody has restored is a file with a hopeful
name, and the restore drill is the only test there is.

**Data Guard** is the standby: a second database kept current from the redo stream, for failover.
Reading from it while it is applying — which is what you would want for reports — is **Active Data
Guard**, a separately licensed option, which is the licence section showing up again in an
architecture decision.

**AWR and ASH** are the performance history and the session sampler, and they are the Diagnostics
Pack. When they are licensed they are genuinely excellent, and an AWR report over the window when
something was slow is the best first artefact there is. When they are not licensed, the equivalent
question is answered from the `V$` views the way it always was, and `V$SQL` and `V$SESSION` are
where to start.

## The `V$` views

Oracle exposes its internal state as views, by convention named `V$SOMETHING`, and they are the
part of the system a curious developer can usefully learn. `V$SQL` holds the statements in the
shared pool with their execution counts and elapsed times, which is `pg_stat_statements` from
lesson 10 by another name; `V$SESSION` shows who is connected and what they are waiting on;
`V$LOCK` shows the locks.

**Which of these you may query is a matter of grants, and the deeper ones a matter of licence.**
Ask before building a habit on one.

## Upgrades

Major-version upgrades are projects rather than tasks: a version certification for every
application that connects, a test environment, a rehearsal, and a window. That is part of why 19c
is so widely deployed — it was the long-term support release, and an organisation that reached it
had a defensible place to stop.

The developer-visible consequence is the one lesson 12 named: **the version in front of you decides
what exists.** `FETCH FIRST n ROWS ONLY` needs 12c, identity columns need 12c, a native SQL boolean
needs the 23ai line. Advice found online about Oracle spans twenty-five years of releases and often
does not say which one it is about.
