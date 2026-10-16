---
title: Where the twelve factors came from
version: 1
---

Heroku was one of the first platforms where a developer pushed code and the platform built it, ran
it and kept it running, on machines the developer never saw. By 2011 its engineers had watched a
very large number of applications go through that, and some patterns kept separating the
applications that moved between machines without trouble from the ones that broke whenever they
were touched. Adam Wiggins, one of Heroku's founders, wrote the patterns down as **the Twelve-Factor
App**, published at `12factor.net`.

The common reading is that they are rules for Heroku, or for containers, or for microservices. **They
are rules for any program that a platform will start, stop, copy and move without asking it**, and
that describes the monolith from lesson 1 as well as a function from lesson 3. Kubernetes, Cloud Run
and Docker Compose all assume them, whether or not their documentation says so.

## The list

| | factor | in one line | in this lesson |
| --- | --- | --- | --- |
| I | codebase | one codebase in version control, many deploys of it | the catalogue's directory |
| II | dependencies | declared explicitly and isolated, never assumed to be on the machine | `requirements.txt` |
| III | config | anything that differs between deploys lives in the environment | starting without `DATABASE_URL` |
| IV | backing services | databases, queues and caches are resources attached by a URL | swapping the database |
| V | build, release, run | three separate stages, and a release never changes once made | tagging an image |
| VI | processes | stateless, sharing nothing; what must persist lives in a backing service | `/hits` on three copies |
| VII | port binding | the app serves HTTP itself, on a port it is given | `PORT` |
| VIII | concurrency | scale out by running more processes | `--scale catalogue=3` |
| IX | disposability | fast to start, graceful to stop | ten seconds against one |
| X | dev/prod parity | the same backing services and versions in development as in production | `postgres:17` in both |
| XI | logs | a stream of events on standard output; storing it is the platform's job | `docker compose logs` |
| XII | admin processes | one-off tasks run as processes of the same release | `catalogue.py migrate` |

The rest of the lesson takes them in that order, grouped where two are one idea, on a version of
Quitanda's catalogue written to follow all twelve.
