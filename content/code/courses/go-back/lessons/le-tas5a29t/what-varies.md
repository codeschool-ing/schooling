---
title: What changes between environments
version: 1
---

boxoffice runs in more than one place. On your machine it listens on `localhost` and talks to a database
with no password. In lesson 16 it runs in a container, where `localhost` is the container itself and
nothing outside could reach it. In production it has a real site in front of it, a database somebody else
runs, and tokens nobody on the team should be able to read off a screen. **The code is the same in all of
them; some values are not**, and those values are its configuration.

A good test of whether something is configuration: does it change between environments while the code
stays the same? Here is everything boxoffice reads from outside itself or has written into its code, as
lesson 13 left it:

| setting | where it is now | varies? |
|---|---|---|
| HTTP address | `localhost:8080`, in `main.go` | yes: a container must listen on every interface |
| gRPC address | `localhost:9090`, in `main.go` | yes, for the same reason |
| database | `DATABASE_URL` | yes, and it is a secret once it carries a password |
| staff tokens | `BOXOFFICE_MANAGER_TOKEN`, `BOXOFFICE_DOOR_TOKEN` | yes, and they are secrets |
| connection pool | `10`, in `main.go` | yes: it depends on the database's limit and on how many copies run |
| write timeout | `10 * time.Second`, in `main.go` | sometimes |
| the site allowed to call | `https://tickets.example.com`, in `routes.go` and again in `ws.go` | yes: a staging site is a different site |
| header timeout | `2 * time.Second`, in `main.go` | **no** |

The last row is the useful one. `ReadHeaderTimeout` is the defence against Slowloris from lesson 1; there
is no environment in which it should be thirty seconds, so making it settable only adds a way to get it
wrong. **Configuration is what legitimately differs, not everything that is a number.** The routes, the
order of the middleware and the validation rules are code too, for the same reason.

The site appears twice, once for CORS and once for WebSockets, which is the other thing configuration fixes:
one setting, read once, handed to everything that needs it.

## Where values come from

This lesson gives every setting three sources, each overriding the one before:

1. **A default in the code**, chosen so that a developer's machine works with nothing set.
2. **An environment variable**, which is how a container platform, a systemd unit or a CI job hands
   settings to a program. This is where production's values live.
3. **A flag on the command line**, for a person at a terminal changing one thing for one run.

The idea of keeping configuration in the environment comes from the twelve-factor app, a set of
practices written up at Heroku in 2011, and it has outlived the platform it was written for: the
environment is the one interface every way of running a program supports.

## One build, many places

What the list leaves out is a setting called "environment" with values like `development` and
`production`, and code that branches on it. **Each such branch is code that only runs in production**,
which means it is first exercised by real users. The environments should differ in values, an address, a
size, a site, and never in which lines run. Lesson 16 builds one binary and one image, and every
environment runs that same file with different values around it.
