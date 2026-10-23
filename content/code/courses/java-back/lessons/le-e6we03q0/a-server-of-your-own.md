---
title: A database server, and where it runs
version: 1
---

Until now the bookshop kept its books in a `Map`, and every restart put back the same three. A real
catalogue has to outlive the process that serves it, so from this lesson on the books live in
**PostgreSQL**, a database server: a separate program, listening on a port, that the application
connects to as a client. It is the same shape as the bookshop and `curl` in lesson 6, one layer
down. This time the bookshop is the client.

That has one consequence before any code. **The application does not contain the database.** The
driver in the bookshop's `pom.xml` knows how to talk to PostgreSQL; it is not PostgreSQL. A server
has to be running somewhere the bookshop can reach, and that is the first thing to set up.

The course uses **PostgreSQL 16**, and every transcript was recorded against it. It is free, it
runs on every system you are likely to own, and it is the database most Spring projects you will
read are written against. There are three places to run it.

## In the same virtual machine — the recommended path

Lesson 1 recommended an Ubuntu Server 24.04 virtual machine for the JDK and Maven. Install
PostgreSQL **in that same machine**, from Ubuntu's own packages, and the bookshop reaches it at
`localhost`, which is exactly what its configuration will say. Your screen then matches the
transcripts in everything but timings and the name in the prompt.

**What it costs:** roughly 170 MB of disk for the packages, most of it a compiler library that
PostgreSQL uses to speed up large queries, plus the data, which for this course stays in the tens
of megabytes. The server takes little memory while it is idle, so the 4 GB the machine was given
in lesson 1 is still enough.

If you have already taken `sql-databases` on this machine, PostgreSQL 16 is installed; skip to the
part of the next section that makes the bookshop's role and database. That course comes after this
one in the `backend` track, and its first lesson will find the server you install here.

## Installed directly on your computer

If your computer **runs Ubuntu or Debian itself** and you skipped the virtual machine in lesson 1,
the commands in the next section work on it as printed.

On macOS, Postgres.app (postgresapp.com) and Homebrew (`brew install postgresql@16`) install it;
on Windows, the installer linked from postgresql.org does. Each creates its first user its own
way, so the `sudo -u postgres` commands below will not match what you see. What matters is the end
state: a server on `localhost:5432`, a role `bookshop` with the password `bookshop`, and a
database `bookshop` it owns. With those, the Java in this lesson runs unchanged.

## Online, on somebody else's server

Hosted PostgreSQL services give you a database and an address, and some have a free tier; Neon and
Supabase are two at the time of writing. **It costs your computer nothing**, and it costs an account
and a network connection on every run. The bookshop's configuration then names their host, their
user and their password instead of `localhost`, and a hosted service asks for an encrypted
connection, which its own page will spell as a URL to paste. No lesson depends on any provider.

Use it if the other two are out of reach today. The price is the one the virtual machine was chosen
to avoid: **when your screen and a transcript disagree, the difference may be the service**, not
what you typed.

Containers are the fourth way, and the course gets there: lesson 19 installs Docker so the tests
can start a throwaway PostgreSQL, and lesson 23 runs the bookshop and its database side by side in
containers. Until then the server is a package on your machine.
