---
title: useAsyncData, for anything that is not one URL
version: 1
---

**`useFetch(url)` is a short way of writing `useAsyncData(key, () => $fetch(url))`.** `useAsyncData`
is the general one: it takes a name for the data, the *key*, and any function that returns a promise,
and gives back the same `data`, `status`, `error` and `refresh`. Everything the last section said
about running once and handing the result over is `useAsyncData`'s; `useFetch` adds only that it
makes the key from the URL and calls `$fetch` for you.

So `useAsyncData` is for the cases where the data is not the answer of one URL: two requests whose
answers are combined, a request whose answer is reduced before the page uses it, or something that is
not a request at all, read from a module on the server. The planner's layout gets one of them, a line
in the footer counting every session planned:

```html
<!-- app/layouts/default.vue: the frame around every page. -->
<script setup lang="ts">
import { version } from 'vue'

// The reader's time zone, as their browser reports it. The server has its own.
const zone = () => Intl.DateTimeFormat().resolvedOptions().timeZone

// How many sessions the planner holds, in every course and every week.
const { data: planned } = await useAsyncData('session-count', () => $fetch('/api/courses'), {
  transform: (planner) => planner.sessions.length,
})
</script>

<template>
  <header>
    <p class="brand"><NuxtLink to="/">Study planner</NuxtLink></p>
  </header>
  <main>
    <slot />
  </main>
  <footer>
    <p>{{ planned }} sessions planned in all. Built with Vue {{ version }}, by Nuxt</p>
    <ClientOnly>
      <p>Days are counted in {{ zone() }}</p>
      <template #fallback>
        <p>Days are counted in your browser's time zone</p>
      </template>
    </ClientOnly>
  </footer>
</template>

<style scoped>
header {
  border-bottom: 2px solid #2f6f4e;
}
.brand {
  font-size: 1.5rem;
  font-weight: 700;
}
footer p {
  color: #666;
  font-size: 0.875rem;
}
</style>
```

`transform` runs on the answer before it is stored, so `planned` is a number and not the planner's
whole data; the next section shows why that matters. `useFetch` takes `transform` too. Restart the
dev server, so that its terminal shows only what this section asks, and open the page:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text '#__nuxt > footer'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of #__nuxt > footer
6 sessions planned in all. Built with Vue 3.5.44, by Nuxt

Days are counted in America/Sao_Paulo
```

## Two requests where there could be one

The server's terminal has two new lines for that one page:

```
ana@dev:~/vue/planner-nuxt$ npm run dev

> dev
> nuxt dev

● Starting Nuxt...
● Nuxt 4.6.2 (with Nitro 2.13.5, Vite 8.3.5 and Vue 3.5.44)

  ➜ Local:    http://localhost:3000/
  ➜ Network:  use --host to expose

● Setting up modules
● Preparing app
● Generating types
● Bundling app
✔ Vite client built in 48ms
✔ Vite server built in 15ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1345ms
◆ Ready in 2.57s  → http://localhost:3000/
  config 229ms · modules 63ms · app 326ms · types 327ms · bundle 197ms · server 1.43s
(node:29444) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
api: GET /api/courses
api: GET /api/courses
```

**The page's `useFetch('/api/courses')` and the layout's `useAsyncData('session-count', …)` are two
keys, so they are two pieces of data, fetched twice.** For two small calls on one server that is
nothing, and keeping the layout's number separate is worth it; the section on keys shows the case
where sharing one key would be the mistake. When two parts of a page really need the same answer, the
plain cure is to fetch it in one of them, the page, and hand it to the other as a prop, so that there is
one call to read and one request to count.
