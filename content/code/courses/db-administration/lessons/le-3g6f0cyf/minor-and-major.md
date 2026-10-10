---
title: Two kinds of upgrade
version: 1
---

A PostgreSQL version number has two parts, and they mean two different jobs. In `16.15`, **`16` is
the major version** and **`15` is the minor release**: the fifteenth set of fixes published for 16.
Lesson 3 asked you to read that string once; this lesson is why.

The mistake worth naming first is to treat the two as bigger and smaller versions of the same
operation. They are not. A minor upgrade swaps the programs and leaves every file of the cluster as
it was. A major upgrade cannot do that, because the new programs do not understand the old files.

## A minor release

A minor release carries bug fixes and security fixes, **never new features and never a change to the
on-disk format**. 16.15 reads exactly the data directory that 16.2 wrote. So the upgrade is three
steps: install the new binaries, restart the server, check the version. The restart is the only
downtime, and it lasts seconds.

The project publishes minor releases for every supported major version on a quarterly schedule, in
February, May, August and November, with extra ones when a security problem cannot wait. They are
**cumulative**: 16.15 contains everything in 16.3 to 16.14, so a server on 16.2 goes straight to
16.15 without visiting the releases in between. Ubuntu packages each one as an ordinary update, which
is how your server arrived on 16.15 in lesson 3.

## A major version

A major version arrives once a year, in the autumn of the northern hemisphere, and carries the new
features. It also changes the **system catalogue** — the tables in which PostgreSQL describes your
tables, columns, types and functions — and sometimes the format of other files in the data
directory. **PostgreSQL 17 refuses to start on a data directory that 16 created**, and the fourth
section of this lesson shows it refusing. Something has to carry the data across, and there are
three ways to do it:

| | how it works | downtime | the way back |
|---|---|---|---|
| **pg_upgrade** | builds a new catalogue and reuses the data files, copied or linked | seconds to minutes, almost independent of size when linked | the old cluster, if files were copied; a backup, if they were linked |
| **dump and restore** | writes everything out as SQL and loads it into the new version | grows with the size of the data | the old cluster, untouched |
| **logical replication** | a new server subscribes to the old one and keeps up with it | the moment of switching, seconds | the old server, still running |

Each major version is supported by the project for **five years** after its release: fixes keep
coming as minor releases, and then they stop. 16 was released in September 2023 and is supported
until November 2028. A server on an unsupported major version gets no security fixes at all, which
is the deadline that usually decides when a major upgrade happens.

**Ubuntu does not change the major version inside a release.** Ubuntu 24.04 ships 16 for its whole
life, and its `apt upgrade` will bring 16.16 and 16.17 but never 17. A newer major version comes from
the PostgreSQL project's own repository, from a newer Ubuntu, or from a managed service's upgrade
button, and the fourth section installs it from the first of those.

Before PostgreSQL 10 the major version had two numbers: 9.5 and 9.6 were different major versions,
and 9.6.24 was a minor release of 9.6. You will still meet servers like that, and the same rule
applies to the first two numbers there.
