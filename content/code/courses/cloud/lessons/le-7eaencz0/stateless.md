---
title: Instances you can throw away
version: 1
---

Everything in the second half of this lesson assumes one thing about the instances in a group:
**any of them can be terminated at any moment, and nothing is lost.** The group terminates them when
they fail a check, when the load falls, and when it rebalances across zones. A program that keeps
something on the instance works perfectly on one machine and breaks, quietly, on several.

## Four things that break

**Sessions in memory.** A program that keeps a user's login in its own memory, or in a file on its
own disk, knows that user only on that instance. With two instances behind a load balancer, the
user's next request may reach the other one and find them logged out. When the group scales in, the
session is gone for everybody on the terminated machine.

**Uploads on the local disk.** A photo saved to `/var/www/uploads` exists on one instance. The next
request for it may reach an instance that never had it, and when the machine is replaced the photo
is gone, as the section on disks said.

**Scheduled jobs.** A cron job that sends the nightly invoices was written for one machine. Put it
in the image of a group of three and three machines send the invoices, every night. Scale to seven
on a busy evening and it is seven.

**Local logs.** Log files written to the instance's disk go with the instance, which is usually the
instance you most wanted to read the logs of: the one that failed its health check.

## Where the state goes instead

The fix in each case is the same move: **the state leaves the instance** and goes somewhere that
outlives every one of them, which all of them can reach.

| what | where it goes |
|---|---|
| uploads, files users create | object storage, lesson 5 |
| sessions | a managed database or a managed cache, shared by every instance |
| the application's own data | a managed database, run by the provider, with its own backups |
| logs and metrics | shipped off the instance as they are written; the `observability` course |
| a job that must run once | one scheduler outside the group, or a lock every instance respects |

What is left on the instance is the program and its configuration, both of which came from the
image and the user data. That is what **stateless** means here: not that the application has no
state, but that none of it lives on the machine running it. Such an instance can be replaced by a
copy from the template without anybody noticing, which is the only kind of instance a group can
manage.

## The same idea, packaged smaller

::: track dba devops devsecops
You have already built container images in the `docker` course, and the word *image* now means two
things. An image in this lesson is a machine image: a whole disk, with an operating system, a
kernel and everything installed on them. A container image is a filesystem for one process, which
runs on a machine like the ones in this lesson and shares its kernel. Both are the same idea: one
thing built once and started many times, each copy disposable. The rules of this section are the
rules a container already lives by, and they apply one level down, to the machines under it.
:::

::: track cloud-engineering data
The `docker` course comes after this one, and it packages the same idea smaller. Instead of an image of a whole machine, with an operating system and a kernel, a container image holds the filesystem for one application. Many of them run side by side on one machine like the ones in this lesson. The rules of this section carry over unchanged: a container is thrown away and
replaced even more readily than an instance, so it cannot keep anything either.
:::

::: track *
Containers take the same idea one level smaller. A machine image is a whole disk with an operating
system; a container image packages one application and its files, and many containers run side by
side on one machine like the ones in this lesson. The idea is the same: something built once and
started many times, each copy disposable, with the state kept elsewhere.
:::
