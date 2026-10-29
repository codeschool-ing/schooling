---
title: The same ideas, under four sets of names
version: 1
---

**React, Vue, Angular and Svelte solve the same problem**: keep a page in step with the data behind it,
in pieces small enough to reason about. So most of what this course taught has a counterpart in each of
the other three, under another name and with its own rules. Knowing the mapping is most of what it
takes to read code written in them, and it is the first thing to learn when moving between them.

| Svelte, in this course | React | Vue | Angular |
|---|---|---|---|
| a component, `.svelte` (lesson 5) | a function returning JSX | a single-file component, `.vue` | a class with `@Component` |
| `$state` (lesson 3) | `useState` | `ref`, `reactive` | `signal()` |
| `$derived` (lesson 3) | worked out during render, or `useMemo` | `computed` | `computed()` |
| `$effect` (lesson 3) | `useEffect` | `watch`, `watchEffect` | `effect()` |
| `$props` (lesson 5) | the function's argument | `defineProps` | `input()` |
| `bind:value` (lesson 5) | a controlled input: a value and an `onChange` | `v-model` | `[(ngModel)]`, `model()` |
| snippets and `{@render}` (lesson 6) | `children` and render props | slots | content projection, `<ng-content>` |
| `{#each … (key)}` (lesson 8) | `.map()` with a `key` | `v-for` with `:key` | `@for` with `track` |
| context (lesson 11) | context, `useContext` | `provide`, `inject` | dependency injection |
| SvelteKit (lessons 12 to 17) | Next.js | Nuxt | Angular's router and SSR |

Each of the other three has a course in this catalogue, built around the same study planner, so the
same feature can be read four ways. The React course takes the rendering model in lesson 3 and
`useState` in lesson 4; the Vue course takes its reactivity system in lesson 2; the Angular course takes
signals in lesson 6 and change detection in lesson 7. Each of them ends, as this one does, with a look at
the others from where it stands.

**A table like this hides the differences that matter**, which are about when code runs and what the
framework knows. The rest of this lesson is about those: what each one sends to the browser, how each
one finds out what to update, and what each one's application framework does with a form.
