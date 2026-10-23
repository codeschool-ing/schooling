---
title: What the box buys, and who buys it
version: 1
---

The course's summary calls Angular the framework of the bank, the insurer and the government. That
is a description of who picks it, not a ranking, and the reasons are worth knowing before you spend
ninety hours on it. They are the same reasons it will feel heavy for the first few lessons.

## Three things a large organisation pays for

**One way per concern.** An organisation with forty front-end developers across eight teams moves
people between teams. When every team's routing, forms and data access are the same libraries
used the same way, somebody who changes team reads the new code on their first day. The previous
section's table is what makes that true: there is nothing per team to choose.

**A calendar.** Angular publishes a major version twice a year, and the dates are regular enough
to plan a budget around. The registry records when each `.0.0` of `@angular/core` was published;
lesson 2 asks it, and gets 20.0.0 on 28 May 2025, 21.0.0 on 19 November 2025 and 22.0.0 on 3 June
2026. Each major is supported for eighteen months: six of active development, then twelve of
long-term support, which means security and critical fixes only.

**Updates that edit your code for you.** `ng update`, which lesson 2 runs, does not only raise
version numbers. A release carries **migrations**, small programs that rewrite the code in your
project where an API changed. Angular moved its templates from `*ngIf` to `@if` (lesson 5) and its
components from NgModules to standalone (lesson 3) this way, across codebases with thousands of
files, and the old forms kept working for several majors while teams moved.

## TypeScript from the first line

Every Angular project is TypeScript, and there is no JavaScript option. That matters more to the
people choosing it than to the people learning it: a type error found by the compiler in a
template is a bug that never reached a tester, and on a codebase that ten people change every day
the compiler is the one reviewer who reads every line. Two sections of this lesson teach you enough
TypeScript to start; each lesson after that adds the part it needs.

## What it costs

- **More to learn before the first screen.** Decorators, the `imports` list, templates, then
  dependency injection by lesson 10. React asks for less on day one.
- **More words per feature.** A component is a class, a decorator, a template and often a
  stylesheet, sometimes in four files. Lesson 2's generator writes the boilerplate, which helps
  and does not make it shorter to read.
- **Weight before you have written anything.** The framework ships the machinery that calls your
  code, so even an application that only says hello has a size. Lesson 2 measures one, and
  `front-performance` is the course about what to do with numbers like that.
- **Two generations of code in the wild.** Angular is part of the way through a long change of
  model: signals instead of zone.js for knowing when something changed (lessons 6 and 7), and
  standalone components instead of modules (lesson 3). New code is written the new way; the code
  you will open at work is often the old one. This course teaches both, and says which is which.

## Who it suits

It suits a project expected to live for years, maintained by people who will not all be there at
the end. It suits less well a weekend prototype, or a team of two that already knows React. None of
that decides your career: the ideas transfer, which is lesson 25's point, and the fork in the
`frontend` track exists so that you learn one framework properly before looking at the others.
