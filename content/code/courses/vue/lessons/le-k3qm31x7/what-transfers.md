---
title: What carries over
version: 1
---

**Most of this course was not about Vue's syntax, and that part goes with you to any of the
other three.** The frontend track puts the four side by side as a choice for one reason, written in
its own note: what you take from one, components, state, routing, the build, is the same idea four
times over.

What carries over almost unchanged:

- **Components with props in and events out.** Lesson 6's `CourseCard` and `SessionRow` are a React
  component with props and a callback, an Angular component with `input()` and `output()`, a Svelte
  component with `$props()`. The decision of where state lives, and that a child asks its parent
  rather than changing what it was given, is the same in all four.
- **Rules in plain functions.** `planner.ts` would run unchanged in any of them, and so would its
  seven tests. That is the most portable code in the planner, and it is portable because it knows
  nothing about Vue.
- **Derived state, not copied state.** The totals were `computed` here, `$derived` in Svelte,
  `computed` in Angular and a recomputed `const` in React, and in none of them were they stored and
  kept in step by hand. Lesson 3's rule, derive what can be derived, is everyone's rule.
- **The build.** Three of the four cards were served by Vite, and Angular's dev server is Vite under
  its own build: lesson 17 applies to them all, `import.meta.env`, `.env` files and plugins included.
- **The tests.** Vitest runs the tests of all four, and Angular's new project already lists it in its
  `package.json`. What lesson 21 said about testing pure functions first, faking the network and the
  clock, and not testing the framework, holds word for word.
- **Server rendering.** Nuxt's SSR, hydration and mismatches have their twins in Next for React,
  Angular's own SSR and SvelteKit, and lesson 19's two todays happen in all of them for the same
  reason.

What does not carry over is the part each framework is proud of: the template syntax, the exact
model of what runs again, the names of the lifecycle hooks, the store library, and the shape of a
project. Those are a week's reading for somebody who has finished one of the four courses properly,
which is what the track's note promises.

## Where to go from here

The catalogue has a course for each of the other three, `react-ts`, `angular` and `svelte`, each
built around the same study planner, so that the second framework is the same application in new
words. After this course the track goes on to `front-quality`, `front-performance` and
`front-delivery`, which are the same whichever framework a student chose: accessibility and tests
in the browser, the cost of a page and how a meta-framework renders it, and how a build reaches its
host. Every one of them has examples that a Vue student can now read in any of the four.
