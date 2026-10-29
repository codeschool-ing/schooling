---
title: Svelte
version: 1
---

**Svelte is a compiler: a `.svelte` file is turned at build time into plain JavaScript that updates
the page directly, and most of what other frameworks do while the page runs is done before it is
sent.** Since Svelte 5, the reactive parts are *runes*, `$state` and `$derived`, marks the compiler
reads. The project, made by `create-vite` like the Vue and React ones:

```
ana@dev:~/vue/compare$ npm create vite@9.3.1 -- svelte --template svelte-ts --no-immediate

> npx
> cva svelte --template svelte-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/vue/compare/svelte...
│
└  Done. Now run:

  cd svelte
  npm install
  npm run dev
```

```
ana@dev:~/vue/compare/svelte$ npm install

added 49 packages, and audited 50 packages in 5s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/svelte$ npm install --save-dev --save-exact svelte@5.57.2

added 2 packages, and audited 52 packages in 660ms

12 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/svelte$ rm -r src/App.svelte src/app.css src/lib
```

The card:

```html
<!-- src/WeekCard.svelte: one course's week, the Svelte way -->
<script lang="ts">
  console.log('Svelte: the script runs')
  let sessions = $state([
    { id: 's3', date: '19 October', minutes: 30, done: true },
    { id: 's6', date: '23 October', minutes: 40, done: false },
  ])
  const planned = $derived(sessions.reduce((sum, s) => sum + s.minutes, 0))
  const done = $derived(sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0))
</script>

<section>
  <h2>Spanish</h2>
  <ul>
    {#each sessions as s (s.id)}
      <li>
        <label><input type="checkbox" bind:checked={s.done} /> {s.date}, {s.minutes} minutes</label>
      </li>
    {/each}
  </ul>
  <p>{done} of {planned} minutes done</p>
</section>
```

and the entry:

```typescript
// src/main.ts: the card, and nothing else, in the page's #app.
import { mount } from 'svelte'
import WeekCard from './WeekCard.svelte'

mount(WeekCard, { target: document.getElementById('app')! })
```

Of the four it is the one closest to Vue's single-file components, a `<script>` and markup in one
file, with three differences in kind:

- **`$state` makes a plain variable reactive**, and changing it, or a field inside it, is an ordinary
  assignment: `bind:checked` writes `s.done` straight into the list, as Vue's reactive object did.
  No `.value`, no setter, no function call to read.
- **`$derived(...)`** is `computed`.
- **The markup is not inside a `<template>`**, and its control flow is blocks, `{#each sessions as s
  (s.id)}`, with the key in brackets.

`npm run dev`, and the tick:

```
ana@dev:~/vue/compare/svelte$ look http://localhost:5173/ --do 'check text=23 October' --text body
[vite] connecting...
Svelte: the script runs
[vite] connected.
-- check text=23 October
== the text of body
Spanish
 19 October, 30 minutes
 23 October, 40 minutes

70 of 70 minutes done
```

The script ran once, like Vue's setup and Angular's constructor. What happened at the tick was a few
lines of generated JavaScript, which updated the text that shows the totals and nothing else.
