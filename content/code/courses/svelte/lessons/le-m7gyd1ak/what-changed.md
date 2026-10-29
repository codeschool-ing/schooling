---
title: What Svelte 5 changed
version: 1
---

**Svelte 5, released in October 2024, replaced the way reactivity is written, and almost everything
else about a component followed.** Svelte 4 made ordinary-looking JavaScript reactive by convention:
a `let` at the top of a component was state, `export let` was a prop, and a label `$:` marked a line
to re-run. Svelte 5 says the same things with runes, which are explicit, work outside components,
and are tracked at runtime instead of guessed at compile time.

The old syntax did not disappear. **Svelte 5 still compiles Svelte 4 components**, in what it calls
legacy mode, so a project can upgrade the compiler first and its components one at a time. That is
why there is so much Svelte 4 code still running, and still being written: tutorials, answers online,
component libraries, and code suggested by tools trained on all of those.

## The same ideas, two spellings

| the idea | Svelte 4 | Svelte 5 |
|---|---|---|
| a value the page depends on | `let count = 0;` at the top of the script | `let count = $state(0);` |
| a value computed from others | `$: double = count * 2;` | `let double = $derived(count * 2);` |
| code that re-runs when values change | `$: console.log(count);` | `$effect(() => console.log(count));` |
| a prop | `export let minutes;` | `let { minutes } = $props();` |
| all props, and the rest | `$$props`, `$$restProps` | `let { a, ...rest } = $props();` |
| a prop the child may write back | `export let value;` and `bind:value` | `let { value = $bindable() } = $props();` and `bind:value` |
| a DOM event | `on:click={handler}` | `onclick={handler}` |
| an event modifier | `on:click|preventDefault` | `event.preventDefault()` in the handler |
| a component event | `createEventDispatcher()`, `dispatch('change')`, `on:change` | a callback prop: `onchange` |
| content passed into a component | `<slot />`, `<slot name="x" />`, `let:item` | `{@render children()}`, snippets |
| a component chosen at runtime | `<svelte:component this={C} />` | `<C />`, since components are dynamic |
| creating a component from JavaScript | `new Component({ target })` | `mount(Component, { target })` |

**Stores did not change.** `writable`, `readable`, `derived` and the `$store` shorthand work in Svelte 5
exactly as in Svelte 4; what changed is that runes in a `.svelte.js` module now cover many of the cases
stores were used for. Lesson 10 is about choosing.

## What the two modes cannot do together

A component is in one mode or the other, decided per file. **In runes mode the legacy syntax is an
error**: `export let` is refused, `$:` is refused, and a plain `let` is just a variable. In legacy mode
runes are not available. Components in the two modes can use each other freely, which is what makes
the gradual upgrade possible.

The planner's `vite.config.js` was written by `sv` to force runes mode on every component of the
project, with one exception for packages in `node_modules`, which may be older. A legacy component
in the project has to say so itself, and the next section shows how.

## SvelteKit moved too

Code written for SvelteKit 1 or 2 carries its own signs of age, and SvelteKit 3 refuses some of them:

| you will read | SvelteKit 3 writes | |
|---|---|---|
| `import { page } from '$app/stores'` and `$page.url` | `import { page } from '$app/state'` and `page.url` | `$app/stores` was removed in 3.0 |
| `import x from '$lib/x.js'` | `import x from '#lib/x.js'` | `$lib` was replaced by Node's own subpath imports |
| `export let data;` in `+page.svelte` | `let { data } = $props();` | the Svelte 4 to 5 change, in a route |
| `throw error(404, …)` | `error(404, …)` | since SvelteKit 2 these throw by themselves |

The last section of this lesson shows what happens when the first two meet a SvelteKit 3 project.
