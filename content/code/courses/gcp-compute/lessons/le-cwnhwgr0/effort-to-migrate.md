---
title: The effort to migrate, which no price list shows
version: 1
---

The table of the previous section prices a service that already fits each option. **Most services
do not fit all four on the day somebody asks**, and the work of making them fit is a cost that
appears on no bill and is paid once, in somebody's weeks. So the second question after "what does
it cost to run?" is "what does it cost to get there?", and it is answered by the service's own
habits.

## What each option asks of the code

Every option in this course runs a program. They differ in what they assume about it:

| the option | what the code has to be |
|---|---|
| a Compute Engine machine | anything that runs on Linux; nothing changes |
| a managed instance group | started by a startup script or baked into an image, and replaceable: no state on the boot disk (lessons 4 and 7) |
| Cloud Run | a container that listens on `$PORT`, keeps no state between requests, and finishes each request within 60 minutes (lesson 8) |
| a Cloud Run job | a container that does its work and exits, up to 7 days per task (lesson 10) |
| Cloud Run functions | one function per entry point, written for the Functions Framework (lesson 17) |
| GKE | a container, plus the Kubernetes objects around it and a cluster somebody looks after (lesson 13) |

**The single most expensive habit to undo is state on local disk**: uploads written to `/tmp`,
sessions kept in memory, a SQLite file next to the program. A machine keeps them by accident;
every other row of the table loses them, on a restart, a scale-in or a new revision. Moving that
state into Cloud Storage, a database or a cache is usually most of the work of a migration, and it
is the same work whichever destination you chose.

## Limits that decide on their own

Some numbers make the choice before any price does. A request that takes 40 minutes fits Cloud
Run's 60 and does not fit an event-driven function's 9; a report that runs for three hours fits a
Cloud Run job and no service at all. A program that needs a GPU runs on Compute Engine, GKE or Cloud
Run with a GPU attached, and the price is lesson 2's arithmetic rather than this lesson's. A
protocol that is not HTTP, a game server on UDP for instance, rules out everything built around a
request: what is left is a machine or a pod.

**Write the limits down before comparing prices**, because a cheaper option that cannot carry the
workload is not an option. The check takes ten minutes and saves the meeting in which somebody
discovers it after the migration has started.

## The cost of running it, after

Effort does not stop on the day of the move. **Operations is the recurring half of migration
cost**, and it is the column that ranks the options in the opposite order from the price:

- a machine needs its operating system patched, its disk watched and its failure noticed;
- a managed instance group takes over the failures and the replacement, and leaves the image;
- GKE takes over much more, and adds a cluster with upgrades, node pools and its own permissions,
  which lessons 13 to 16 show is a subject of its own;
- Cloud Run leaves you the container and its configuration, and very little else.

A team of two that saves 40 dollars a month by running machines instead of Cloud Run is paying for
it in afternoons. Sometimes that is the right trade; it is never a free one.
