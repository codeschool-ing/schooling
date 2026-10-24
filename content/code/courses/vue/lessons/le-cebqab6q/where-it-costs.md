---
title: Where TypeScript costs something
version: 1
---

**TypeScript is not free, and the honest way to decide whether a project wants it is to know what it
costs.** For the planner the costs are small and measurable, and the benefits are the errors of this
lesson, found by a program. For some code the balance goes the other way, and the Vue-specific costs are
worth knowing in particular.

## What the planner paid

The checker, and the disk it took:

```
ana@dev:~/vue/planner$ time npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit


real	0m2.086s
user	0m4.228s
sys	0m0.256s
```

```
ana@dev:~/vue/planner$ du -sh node_modules
126M	node_modules
ana@dev:~/vue/planner$ du -sh node_modules/typescript
24M	node_modules/typescript
```

**About two seconds to check the whole planner**, on the recording machine, and a compiler that is a
large share of what `node_modules` holds; neither reaches the student's browser. And the code: changes
to nine files in `src` besides the two new ones, almost all of them parameters, `ref<…>()` and `?.`.
Nothing about how the planner runs changed, and the build's JavaScript is the same, because types are
removed before anything is bundled.

## Where it costs more than it looks

- **Libraries without good types.** A library written in JavaScript with no types, or wrong ones, makes
  you write declarations for it or accept `any` at its edge. Vue, Vue Router, Pinia and Vite are written
  in TypeScript, so the planner met none of this.
- **Types that describe the framework rather than the app.** `InstanceType<typeof PlannerDialog>` is
  correct and nobody's idea of readable. Every Vue feature that crosses a component boundary, template
  refs to components, provide and inject (lesson 8's keys become `InjectionKey<T>`), generic components,
  has a typed form, and each is one more thing to learn.
- **The template is checked by a second program.** `tsc`, the plain TypeScript compiler, does not
  understand `.vue` files; `vue-tsc` does, and it must be kept at a version that matches both Vue and
  TypeScript. TypeScript 7, rewritten in Go and much faster, is current at the time of writing, and
  `create-vue` 3.24.0 still installs 6.0 by default, offering the Go-based compiler only behind a flag of
  its own, `--tsgo`; the planner follows the default.
- **Assertions hide what they assert.** `as Something` and `!` tell the checker to trust you. Each one
  is a place where the types say something the code does not prove, and a codebase full of them has the
  cost of types and fewer of the benefits.

## When to use it

For an application that will live for years, be changed by several people, or have data shapes shared
between many components, the planner's case: yes, from the start, because adding types later, as this
lesson did, means reading every error at once. For a prototype of an afternoon, a widget on a page
(lesson 1), or a course's sandbox: JavaScript is fine, and the conversion is an afternoon's work when it
grows. **The rest of this course writes the planner in TypeScript**: lesson 17's build checks it, and
lessons 18 to 21 start from typed code.
