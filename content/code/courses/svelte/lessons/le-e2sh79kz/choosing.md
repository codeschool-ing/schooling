---
title: What Svelte costs, and what it gives
version: 1
---

**Svelte's advantages are the ones this course kept measuring**: little JavaScript sent, a component
that reads like the HTML it produces, state that is a variable, and, with SvelteKit, forms that work
before any script has arrived. They are real, and the counter of this lesson put a number on the first.

**Its costs are just as real, and an honest choice weighs them:**

- **A smaller ecosystem.** React has a library for nearly everything, and most of them assume React.
  A date picker, a rich text editor, a chart, an authentication service's ready-made screens: for
  React there are often several, for Svelte there may be one, or a library written for plain
  JavaScript that you wrap yourself, which lesson 10's stores and lesson 11's context make easier but
  not free.
- **Fewer people who know it.** A team hiring for React draws from a far larger pool, and most front-end
  developers have met React whatever else they know. That matters more to a company than to a project.
- **Change.** Svelte 5 replaced the reactivity of Svelte 3 and 4 with runes, and lesson 4 exists because
  a great deal of code, documentation and answers on the web still describe the older one. SvelteKit 3
  renamed things again, `$lib` and `$app/stores` among them. React has had its own upheavals, hooks and
  then Server Components, and Angular has moved from zones to signals; none of the four stands still.

**Choosing, then, is mostly about the situation, not the framework.** A team that already knows one of
them is usually best served by it. A project that depends on a particular library is served by the
framework that library is written for. A site where the first load on a slow phone decides whether
people stay, or a form that must work everywhere, is where Svelte and SvelteKit's defaults earn the most.
An application that a large organisation will maintain for a decade, with many teams and strong
conventions, is where Angular's structure, everything in one framework and one way to do it, earns the
most.

**What carries over is most of what this course taught.** Components with props and children, state
that is derived rather than copied, the address as the place for what a person is looking at, a load
function that runs on the server, a form that posts, the check that runs on the server whatever the
browser checked, the test with JavaScript switched off: each of the other three has its own name for
every one of them, and the planner can be built in each. Their courses build it, from their own side.
