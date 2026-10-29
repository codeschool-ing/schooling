---
title: Setup or onMounted
version: 1
---

**Work that needs the page goes in `onMounted`; everything else goes in setup.** The question comes up
most with loading data, and the answer there surprises people who learned React first: start the
request in setup, not in `onMounted`.

```html
<!-- src/demos/SetupOrMounted.vue -->
<script setup>
import { onMounted } from 'vue'

console.log(`setup: the heading is ${document.querySelector('h2')}`)
fetch('/courses.json').then(() => console.log('setup: the request started in setup has answered'))
onMounted(() => {
  console.log(`mounted: the heading is ${document.querySelector('h2').outerHTML}`)
})
</script>

<template>
  <h2>Statistics</h2>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=SetupOrMounted' --text -
[vite] connecting...
[vite] connected.
setup: the heading is null
mounted: the heading is <h2>Statistics</h2>
setup: the request started in setup has answered
```

- **In setup, the heading is `null`**: the template has not been rendered. Anything that needs an
  element waits for `onMounted`.
- **In `onMounted`, the heading is there.**
- **The request started in setup answered after both.** It was sent before the component was even on
  the page, so it was in flight while Vue rendered and mounted. Starting it in `onMounted` would have
  waited for the render first, and gained nothing: a request does not need the page.

The planner has loaded its courses this way since lesson 2, with `fetch` at the top level of the script.

## Why React code does it the other way

A React component's body runs on every render, so a request written there would be sent on every
render. React code starts requests in an effect, which runs after the render, once. Vue's setup runs
once by construction (lesson 2), so the reason does not apply, and moving the request into `onMounted`
only delays it. **Port the intent, not the hook.**

## The case that decides it later

Lessons 18 to 20 render the planner on a server. **On the server, setup runs and `onMounted` does
not**: there is no page to mount into. So code in setup runs in both places, and code in `onMounted`
runs only in the browser. A request in setup will be made on the server, which is often what you want
and is what Nuxt's `useFetch` is built around (lesson 20); a call to `localStorage` or `window` in setup
will fail on the server, because neither exists there. When the planner moves to Nuxt, its
`localStorage` reads move into `onMounted` for exactly that reason.
