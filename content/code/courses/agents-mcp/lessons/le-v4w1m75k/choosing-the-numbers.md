---
title: Choosing the numbers
version: 2
---

A limit that is too tight stops runs that would have succeeded; one that is too loose lets a looping run spend money and time before anything catches it. Neither error is visible until you measure, so the numbers should come from runs, not from instinct.

**Measure the distribution, not the average.** Run the agent over a set of realistic tasks (lesson 18 builds one) and record steps, tokens and seconds for each successful run. The stand-in's runs in this lesson took four steps, and every run of `llama3.2:3b` in this course has taken one or two, and in section 04 one of its replies took two minutes. A larger model's numbers spread differently, and they spread. The limit belongs above the slowest successful runs, the 99th percentile for instance, with a margin, so that it fires on runs that have gone wrong and almost never on runs that are merely long.

**Set each budget from its own failure.** The step limit catches loops, so it sits just above the longest legitimate path. The token budget catches runaway context, so it follows from the largest observation a tool can return times the number of steps it travels. The time budget comes from outside the agent: how long the customer will wait, or how long the queue can afford.

**Different tasks, different limits.** A question about an order and a research task are different workloads. One global limit set for the research task lets the order question loop for a long time before stopping; one set for the order question stops every research task. A limit per task type, chosen by the router that decided the task was an agent's (lesson 2), fits both.

**Watch how often each limit fires.** A limit that never fires may be too loose, or the agent may be healthy. One that fires on one run in a hundred is doing its job. One that fires on one run in five is telling you either that the limit is wrong or that the agent is, and the stopped outcomes, with their plans and traces, say which.

## This machine's numbers are this machine's

The timings in this lesson come from a small model on four processors with no graphics chip, and the stand-in's step counts were written in advance, so none of them is a recommendation for a real deployment. What carries over is the method: limits are measurements with a margin, enforced by the host, reported when they fire.
