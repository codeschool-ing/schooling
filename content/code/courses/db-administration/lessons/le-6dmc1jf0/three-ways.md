---
title: A package, a container and a managed service
version: 1
---

Whichever way you install it, **the server is the same program**: a process called `postgres`,
a directory of data files, a configuration file and a log. What changes between the three ways
of having one is who owns each of those four things, and that decides what you can do when
something goes wrong.

## A package

A **package** is the server built by your operating system's distributor and installed by its
package manager. On Ubuntu that is `apt install postgresql`, and what arrives is a program in
`/usr/lib/postgresql/16/bin`, a service that systemd starts at boot, a data directory under
`/var/lib/postgresql` and a configuration file under `/etc/postgresql`. Security fixes arrive
with the rest of the system's updates.

You own all four things. You can read every file, change any setting, restart the service, fill
the disk and watch what happens. Nobody else will notice a fault before you do, and nobody else
will fix it.

## A container

A **container** is the same program packed into an image together with the libraries it needs,
run by Docker or Podman as an isolated process. The official `postgres:16` image starts a server
with one command, and throwing it away is one more.

You still own the four things, but they live somewhere else. The data directory is a **volume**
the container runtime keeps for you, and the configuration file sits inside it. The log goes to
the container's standard output rather than to a file. There is no systemd unit: the container
runtime decides when the server starts and stops. A container is excellent for a development
machine or a test that needs a clean server every run. On a production server it adds a layer
somebody has to understand at three in the morning.

## A managed service

A **managed service** is a server somebody else runs for you: Amazon RDS, Google Cloud SQL,
Azure Database for PostgreSQL and many smaller providers. You get an address, a port and a
user, and you never see the machine.

What you give up is most of this course. There is **no shell on the server**, so no data
directory to look at and no log file to read except through the provider's console. There is
**no real superuser**: the provider keeps that role and gives you one with fewer rights. The
configuration file becomes a form or an API call, and some parameters are not offered at all.
In return, backups, failover and minor upgrades become a setting rather than a project.

## Who answers for what

| | package | container | managed service |
|---|---|---|---|
| installs security fixes | you, with `apt` | you, by pulling a new image | the provider |
| reads the data files | you | you, through the volume | nobody but the provider |
| changes any parameter | you | you | only those the provider offers |
| holds the superuser | you | you | the provider |
| restarts a stuck server | you | you | the provider, or a button |

Two things stay yours in every column: **the roles and grants inside the database**, and **the
schema** — what the tables are and how they change. A managed service runs autovacuum for you,
but it cannot know that one of your tables needs a different setting. Lessons 11 to 17 and 22
apply to all three.

**This course uses a package**, on a machine you own, because it is the only one of the three
where everything the course talks about is in front of you. The next section builds it.
