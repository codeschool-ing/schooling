---
title: Where each one fits
version: 1
---

Declarative is not always better. It needs every step to have an output that can be compared, and
some steps have none:

- Sending something: an e-mail to the managers, a message to a chat channel, a call that charges
  a card. There is no file that says *the e-mail exists*, and running the step twice sends it twice.
  Steps like these are imperative by nature, and belong at the end, guarded so that they run once.
- Deciding while running: a loop over whatever the API returned tonight, a branch on a count.
  A declaration fixes the graph before anything runs; a script decides as it goes. This was
  Prefect's case in lesson 13.
- Waiting and retrying, where *try again in fifteen seconds, then thirty* is a sequence in time.
  Lesson 10's retries, sensors and deadlines are imperative machinery wrapped around each step.

And imperative is not always simpler. Once a pipeline has more than a handful of steps, the order
written by hand and the work redone on every run are where the time and the mistakes go.

So most real pipelines are both, in layers, and the course has already built one. **Airflow
declares the graph and runs imperative tasks**, retried and timed. One of those tasks is `dbt build`,
which is **a declaration of tables**. Inside the warehouse, every model is a `select`, the most
declarative thing in this course. The question at each layer is the same: is this step better
described by *what it produces* or by *what it does*? Where it produces something that can be
checked, declare it. Where it only does something, write the steps, and make them safe to repeat.
