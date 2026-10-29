---
title: What a context holds
version: 1
---

**A context holds whatever value was set, once, and passes on exactly that value.** It is not a second
reactivity system. Children update when what they read through the context changes, so what you put
in a context decides whether they ever will.

The planner's context holds the `Planner` instance, an object whose fields are signals. A child keeps
the instance and reads `planner.total` whenever it needs it, and every read is tracked, so a child
always sees the current total. That is the shape to use: **put an object with reactive fields in a
context, and read the fields where they are used.**

Two things break it, and both are worth seeing on paper before meeting them in a page:

| the parent sets… | a child reads… | what happens |
|---|---|---|
| `setTotal(planner.total)`, a number | `getTotal()` | the number as it was when it was set, for ever: a number has no fields to track |
| `setPlanner(planner)`, then later `planner = new Planner(…)` | `getPlanner()` | the old instance: the children kept the object they were given, not the variable |
| `setPlanner(planner)`, and changes go through its fields and methods | `getPlanner().total` | the current total, always |

The first row is lesson 2's `hours` once again, a value copied once, in a new place. Svelte's compiler
warns about the plain version of it, `setContext('total', total)` with a `$state` variable, with the
same `state_referenced_locally` you met in lesson 2. When a single changing value really is all a
child needs, pass a function that reads it, `setTotal(() => planner.total)`, and call it in the child;
a function call is read when it runs, so it stays current.

The second row is why the planner is set as an instance and never replaced. Lesson 13 loads the data
from the server, and from then on the planner's fields are updated in place rather than a new
`Planner` made, so that every component holding the instance keeps working.
