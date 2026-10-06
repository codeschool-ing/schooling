---
title: Plan first, or decide as you go?
version: 1
---

Lesson 3's agents decided one step at a time: look at the last result, choose the next call. That works well for short tasks and badly for long ones, where the model can lose track of the second half of a request while chasing the first. The other extreme is to write the whole plan before acting and then execute it, which works badly whenever a step's result changes what the next steps should be. **Most useful agents do both: they write a plan, act on it, and rewrite it when a result says the plan was wrong.**

| | decide as you go | plan, then execute | plan, act, revise |
|---|---|---|---|
| how | each step chosen from the last result | all steps written first, then run in order | a written plan, updated as results arrive |
| good at | short tasks; surprises | long tasks with a known shape | long tasks with surprises |
| fails when | the request has several parts and one is forgotten | a step's result invalidates the rest | the plan and the work drift apart (section 06) |
| visible to a person | only through the trace | as a plan, before anything runs | as a plan that changes, and why |

The third column is what this lesson builds. Its practical advantage is that **the plan becomes an object the host holds**, not a thought inside the model. The host can print it, store it, show it to the customer as progress, hand it to a person when the run stops, and compare it with what the tools actually returned.

## Why write the plan down

A model asked to plan "in its head" plans in its reply text, which is gone from view the moment the next reply arrives and has no structure anything can check. A plan written through a tool call has a schema: a list of steps, each with a status from a closed set. That makes three things possible that free text does not:

- **progress is countable**: three steps, one done;
- **a stopped run is resumable by a person**: here is what was planned and how far it got;
- **a changed plan is visible**: a step marked `dropped` says the model decided not to do it, rather than silently forgetting it.

Coding agents do exactly this with a to-do list they keep updating as they work, and for the same reasons. The cost is a few extra steps and tokens per run, which section 04 counts.
