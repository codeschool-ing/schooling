---
title: The problem context solves
version: 1
---

**Props travel one level at a time.** A value a component three levels down needs has to be passed by
every component on the way, including the ones that never use it, which only hand it on. That is
called **prop drilling**, and it is not wrong; it is honest about where data goes. It becomes a
problem when the components in the middle grow props they do not care about, and every new need deep
in the tree means editing every file above it.

The planner is about to meet it. `Planner.svelte` has grown again since lesson 10: the sentence about
how much is done and the list of minutes per day are two pieces with a name each, and both should be
components of their own. Both need the planner: the sentence reads `total` and `doneMinutes`, the
list reads `week` and `byDay`. As props, that is four values handed down from `Planner.svelte`, and
the day the list wants to show which day has the most minutes, a fifth.

## What would be passed, and what is already there

Look at what the two components need, and it is never a single value: it is **the planner**. They
read a few of its fields each, and the fields they read will change as they change. Passing the whole
instance as a prop, `<Days {planner} />`, is better than passing four fields, and it is how many
codebases do it.

**Context** is the other way: a component makes a value available to every component inside it, at
any depth, without passing it through each one. It is the right tool when three things are true at
once:

- many components inside one part of the page need the same thing;
- that thing belongs to the part of the page, not to the whole application;
- passing it through the components in between would only be noise.

The planner is exactly that: everything inside `Planner.svelte` works on one `Planner`, the one that
component created, and nothing outside it needs that planner at all. The next section puts it in
context.

## What context is not

It is not a global. Each component that sets a context provides it to **its own** descendants, so two
planners side by side on one page would each give their children their own instance. It is not
reactive by itself either: it hands over whatever value was set, once, and the value's own reactivity
is what makes children update. And it is set only while a component is being created, which the
section after next shows failing when that rule is broken.
