---
title: A rollback nobody has run does not work
version: 2
---

The way back is used on bad days only, which means it is the least exercised path in the whole
pipeline. Here are two things about `rollback.sh` that are easy to miss until they matter.

## Rolling back twice goes forward

```
ana@laptop:~/shipquote$ ops/rollback.sh production
smoke: http://127.0.0.1:8300 is up and running 1.6.0
ana@laptop:~/shipquote$ readlink ~/envs/production/current ~/envs/production/previous
releases/shipquote-1.6.0
releases/shipquote-1.5.0
ana@laptop:~/shipquote$ ops/rollback.sh production
smoke: http://127.0.0.1:8300 is up and running 1.5.0
```

`rollback.sh` swaps `current` and `previous`, so a second rollback undoes the first: production is
on **1.6.0 again**, the release with the bug. Someone who runs it twice in a panic, or two people who
each run it once, put the bug back in front of customers. The script only remembers one step back,
and it has no idea which of the two releases was the good one.

## There is nothing to roll back to the first time

Staging, made again from nothing for the purpose, gets its first deploy:

```sh
mkdir ~/envs/staging
echo SHIPQUOTE_PORT=8200 > ~/envs/staging/config.env
```

```
ana@laptop:~/shipquote$ ops/deploy.sh staging dist/shipquote-1.6.1.tar.gz
smoke: http://127.0.0.1:8200 is up and running 1.6.1
ana@laptop:~/shipquote$ ops/rollback.sh staging; echo "exit $?"
rollback: staging has no previous release
exit 1
ana@laptop:~/shipquote$ ls ~/envs/staging/releases
shipquote-1.6.1
```

A first deploy to an environment leaves no `previous`, and the script says so and exits 1. That is
correct behaviour, and also a surprise to somebody who expected a way back: staging has been
deployed exactly once, so there is nothing behind it.

## Rehearse it

Both surprises are cheap to discover on a calm day and expensive during an incident. Teams that
trust their rollback do three things:

- **Run it in staging regularly**, as part of a release, not only when something breaks. A rollback
  that ran last week is a rollback that works.
- **Know what it will go back to before running it.** `readlink ~/envs/production/previous` answers
  that in the lab; a real deployment tool shows the previous version and its age.
- **Write down who decides.** One person calls the rollback, one person runs it, everybody else
  watches. Two people fixing the same incident in parallel is how the double rollback above happens.
