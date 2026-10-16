---
title: What a runbook holds
version: 1
---

The top of the page answers the questions somebody has in the first minute: where to start, whose
system it is, and when the page was last proven right. Then **where things are**, with real
addresses, because "the database" is not something a person can type. Then one entry per
**scenario**, each in the same shape:

| part | what it says | from |
|---|---|---|
| **Expect** | what this failure looks like when the system copes: the numbers | lesson 23's rehearsal |
| **Check** | how to see whether it coped | `status.sh`, below |
| **If not** | the next step, and which other scenario it leads to | |
| **Then** | what to do after it has coped, and what not to do yet | lesson 22's decisions |
| **Done when** | the state that ends the incident, as something you can see | lesson 22 |
| **Tell** | who hears, and when | lesson 22's messages |

Each command is written out whole, copied from a run that worked, not paraphrased: "restart the
node" is a sentence somebody has to translate at three in the morning, and
`patroni ~/patroni/pg2.yml` is not. Each number is a measured one, with where it was measured, so that
somebody reading "about 30 seconds" knows whether 50 is a problem.

The scenarios are the ones this course has caused on purpose: a dead leader (lessons 15 and 16), a node
that will not rejoin (lesson 15's rewind and its configuration), etcd lost (lesson 16), a frozen leader
(lesson 17), a lagging or disconnected standby (lesson 13), a slot filling the disk (lesson 11), rows
deleted by mistake (lessons 6 and 20), and a restore from the archive (lessons 5 to 7). Further down
this lesson, the first of them is written out in full.
