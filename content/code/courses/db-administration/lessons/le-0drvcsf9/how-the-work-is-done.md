---
title: How the work is done, so that it can be trusted
version: 1
---

The technical lessons of this course are about what to change on a server. This section is about
how, because the same change done carelessly and done well differ in exactly the way that matters at
three in the morning. Six habits run through the rest of the course; each is cheap, and each is
something the course does in front of you rather than tells you about.

**Read the log first.** Before restarting anything, before searching the internet, read the last
lines of the server's log. PostgreSQL says what is wrong in plain sentences more often than people
expect, and lesson 3 already showed where to find it.

**Measure before and after.** A change made "to improve performance" without a number before it and
a number after it is a guess with consequences. When a lesson changes a setting, it shows the
measurement on both sides, and the measurement is what you keep.

**Change through files, not through memory.** A setting typed into a session and forgotten is a
server nobody can rebuild. Lesson 5 shows where a change belongs, and lesson 23 puts the files under
version control so that the server's configuration has a history like any code.

**Rehearse on a copy.** Anything that cannot be undone in a minute — an upgrade, a large schema
change, a configuration that needs a restart — is done first somewhere it does not matter. Lesson 20
makes a second cluster just to rehearse an upgrade on it.

**Say what you are about to do.** A restart, a migration and a long maintenance job each land on
somebody else's application. Telling the people who depend on the server, before and after, costs a
message and saves an incident.

**Write down what you did.** The time, the command, what it printed. During an incident this is the
difference between an explanation and a reconstruction, and lesson 24 makes it a document.

## Why these and not cleverness

None of the six needs talent, and that is the reason they are here. A database administrator is
trusted with the one system a company cannot easily rebuild, and the trust comes from being
predictable more than from being clever: the change was announced, measured, reversible and written
down. The deep technical knowledge in the rest of the course makes you able to do the work; these
habits make it safe to let you.
