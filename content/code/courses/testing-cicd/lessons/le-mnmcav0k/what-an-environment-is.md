---
title: What an environment is
version: 2
---

An **environment** is a place where a release runs: the machines, the configuration, the data and
the services around it. Most teams have at least three, and the names are close to universal:

| environment | who uses it | what it is for |
|---|---|---|
| **development** | the developers | trying a change, with fake or seeded data |
| **staging** (also *homologação*, *pre-production*) | the team, sometimes the business | proving a release works somewhere like production |
| **production** | the customers | the real thing, with real data and real money |

A common wrong picture is that environments differ in **code**: a "development version" and a
"production version" of the program. They should not. The program is the artifact of lesson 7, the
same bytes everywhere. **What differs between environments is everything around the program**:
which port it listens on, which carrier it asks, which database it writes to, who can reach it, and
how much traffic it sees.

## Why more than one

Each environment exists to catch a class of mistake before the next one sees it. Development catches
the mistake while it is being made. Staging catches the mistake in the release, its configuration
and its deployment, before a customer does: lesson 7's port typed with a letter O was exactly that
kind. Production is where nothing new should be learnt.

The cost is real. Every environment is something to pay for, keep running, keep in step with the
others and keep secure. Teams with few users and cheap rollbacks sometimes run only development and
production, and that can be the right call: the repository that publishes this course deploys
straight to production after its checks, as lesson 7 section 05 noted. The question this lesson
keeps asking is **what would a staging environment catch that nothing else does, and is that worth
what it costs?**

## The lab's environments

From here on `shipquote` runs in three environments on one machine, each a directory with its own
`config.env` and its own process: `dev` on port 8100, `staging` on 8200 and `production` on 8300.
Staging and production each talk to their own carrier, both of them the lab's stand-in started
twice, on ports 9091 and 9092, with different tokens. It is a model, and section 06 says what a real
staging adds; the rules it demonstrates, one artifact, configuration outside the code, and no change
made by hand, do not depend on the scale.

To build it, stop what lesson 7 left running and start from no environments at all. The `preview`
of lesson 7 never started, so `kill` complains about it, and that is the only complaint expected:

```sh
kill $(cat ~/envs/*/pid)
rm -rf ~/envs
```

Then the two carriers, lesson 2's stand-in started twice, each with a port and a token of its own,
each in a terminal of its own. Both tokens are values made up for the lab and open nothing but these
two processes:

```sh
CARRIER_TOKEN=lab-sandbox-token CARRIER_PORT=9091 python3 ~/carrier/server.py
CARRIER_TOKEN=lab-live-token CARRIER_PORT=9092 python3 ~/carrier/server.py
```
