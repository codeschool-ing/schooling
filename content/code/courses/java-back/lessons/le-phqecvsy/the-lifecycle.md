---
title: Phases, goals and the build lifecycle
version: 1
---

`mvn compile`, `mvn package` and `mvn dependency:tree` look like three commands of one kind. They
are two kinds. `dependency:tree` names a **goal**: one task of one plugin, run once. `compile` and
`package` name a **phase**: a step in a fixed sequence called a **lifecycle**, and asking for a
phase runs every phase before it as well.

Maven itself does almost nothing. **The work is done by plugins**, each a jar of goals, and the
lifecycle is the order in which their goals run. A project with `jar` packaging gets a goal bound
to six phases of the default lifecycle without writing a line about it, and two more, `install`
and `deploy`, at the end:

@@FIG-LIFE@@

## Reading a build

That figure is what scrolls past when you package the project. Each line between dashes is one
goal running, in the form `plugin:version:goal (execution) @ project`:

@@CAPTURE package@@

@@PACKAGE-PROSE@@

## The phases you will type

**`mvn test`** stops after the tests, which is the quick question "does it still work", and
`-q` (quiet) prints only warnings and errors, so a passing run prints nothing at all:

@@CAPTURE test@@

**`mvn package`** is the one above. **`mvn verify`** runs everything `package` does and then the
phase where integration tests and checks belong; this project has none, and lesson 19 adds them.
**`mvn install`** copies the project's jar and pom into your local repository, where another
project on the same machine can name it as a dependency like any library from outside:

@@CAPTURE install@@

**`mvn deploy`** would upload them to a shared repository, which needs a server and credentials
this course does not set up.

## Another lifecycle, and flags worth knowing

`target/` is the build's output and nothing else, and `mvn clean` deletes it. `clean` is a phase
of a second, separate lifecycle, so `mvn clean package` names one phase of each and runs both in
order: first an empty `target/`, then a full build. Use it when a build behaves in a way you cannot
explain, and not out of habit, since it throws away compiled classes the next build would reuse.

Three flags appear in this course. `-q` is above. `-B` (batch mode) turns off colours and the
progress counters of downloads, which is what you want in a script or a log file. And
`-DskipTests` runs every phase but executes no test, for a build whose tests you have just run;
a build that ships should never use it.
