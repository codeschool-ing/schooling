---
title: Stop the old, start the new
version: 2
---

Every deploy in lesson 7 did the same thing: stop the process that was running, start the new
release, check it answers. That strategy has a name, **recreate**, and it has one property every
other strategy in this lesson exists to remove. Between the stop and the start, nothing answers.

Here production runs 1.5.0 on port 8300, deployed the way lesson 7 deployed it:

```sh
ops/deploy.sh production dist/shipquote-1.5.0.tar.gz
```

A loop asks `/health` every 50 milliseconds and prints the status code; half a second in,
`restart.sh` stops the process and starts it again.

```
ana@laptop:~/shipquote$ for i in $(seq 60); do curl -s -o /dev/null -w "%{http_code} " --max-time 1 http://127.0.0.1:8300/health; sleep 0.05; done & sleep 0.5; ops/restart.sh production; wait; echo
200 200 200 200 200 200 200 200 200 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
```

`000` is curl's way of saying no answer came back at all: the connection was refused. Twenty-four
checks in a row got it, which at one check every 50 ms or more is well over a second without
service. A customer asking for a quote in that second saw an error page.

## Where the gap comes from

The gap is the sum of everything between the old process letting go of the port and the new one
taking it:

- the old process shutting down, and here also the system collecting it;
- the interpreter starting and importing the program;
- whatever the program does before it listens: reading configuration, opening a database
  connection, warming a cache.

`shipquote` does almost nothing at start-up, and still lost more than a second. A service that
loads a large model or runs a migration before it listens can lose minutes.

## When recreate is the right answer

It is not always wrong. Recreate is the only strategy in which **two versions never run at the
same time**, and some changes need exactly that: a change to how data is stored that the old
version cannot read, or a job that must never run twice. It is also the simplest, and for an
internal tool used during office hours a deploy at 7 in the morning costs nobody anything.

What it should not be is the strategy nobody chose. The rest of this lesson is the alternatives,
each one buying something with something else. Stop this production now,
`kill $(cat ~/envs/production/pid)`: from section 06 on, port 8300 belongs to the router.
