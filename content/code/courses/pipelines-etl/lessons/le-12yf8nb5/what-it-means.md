---
title: What idempotent means, and why everything needs it
version: 1
---

A step is **idempotent** when running it twice leaves the same result as running it once. Not a
similar result, not one that is right on average: the same rows, the same values, the same count.
Once it has run, running it again changes nothing.

Every lesson since the eighth has assumed it without saying so. Lesson 10's **retries** run a task
again after it failed halfway. Lesson 10's **clear** runs it again days later. Lesson 9's
**backfill** runs a week of runs over days that may already be loaded. Lesson 13's Prefect reran
everything on every call, and Luigi and `make` resumed a pipeline after a failure, running the steps
that had not finished — some of which had started. **Every orchestrator in this course runs steps
more than once**, and nothing in any of them knows whether that is safe. Only the step can be.

The name comes from mathematics, where a function is idempotent when applying it twice is the same
as applying it once: rounding a number, taking an absolute value, sorting a list. In a pipeline the
"function" is a step and the "value" is the state it leaves behind: a table, a file, a row in
another system.

This lesson does three things with the idea. It shows a load that is not idempotent and what that
costs, the shapes a load can take that are. It turns *idempotent* from a claim into a test that is
run, as lesson 12 did with the beliefs about the data. And it finishes the business lesson 11 left
open: the fact table that drifted, made safe to rebuild every night.
