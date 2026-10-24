---
title: The double fetch, and the empty first render
version: 1
---

**A component's setup runs on the server and again in the browser, so a request written in it with
plain `$fetch` is made twice.** It is the mistake every newcomer to server rendering makes once,
because the code looks like the one the Vite planner had. A page to show it, in a folder of demos
this section deletes at its end:

```html
<!-- app/pages/demo/twice.vue: $fetch in setup, the way not to do it -->
<script setup lang="ts">
const data = ref()
data.value = await $fetch('/api/courses')
</script>

<template>
  <p>{{ data.sessions.length }} sessions</p>
</template>
```

Restart the dev server, so its terminal starts clean, and open the demo:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/demo/twice --network --text main | grep -v '^net  GET /_nuxt'
net  GET /demo/twice  200
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
net  GET /api/courses  200
== the text of main
6 sessions
```

**The browser asked for `/api/courses` itself**, although the page arrived with the number drawn. The
server ran the setup, fetched, drew *6 sessions*, and sent the HTML; the browser ran the same setup to
hydrate, and `$fetch` knows nothing about payloads, so it fetched again. The server's terminal agrees:

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
✔ Vite client built in 56ms
✔ Vite server built in 22ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1279ms
◆ Ready in 2.68s  → http://localhost:3000/
  config 304ms · modules 62ms · app 358ms · types 350ms · bundle 234ms · server 1.37s
(node:29744) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
api: GET /api/courses
api: GET /api/courses
api: GET /api/courses
```

Three lines for one visit: the layout's `session-count`, fetched by the server; the page's `$fetch`,
made by the server; and the same `$fetch` again, made by the browser. On the planner the cost is a
request; on a page whose data changed in the milliseconds between the two, it is also a hydration
mismatch, the server's answer drawn and the browser's expected. `useFetch` and `useAsyncData` exist
to make it one.

## Fetching in onMounted instead

The other habit from client-side code is to fetch in `onMounted`, which runs only in the browser:

```html
<!-- app/pages/demo/mounted.vue: fetched in the browser only -->
<script setup lang="ts">
const data = ref()
onMounted(async () => {
  data.value = await $fetch('/api/courses')
})
</script>

<template>
  <p v-if="data">{{ data.sessions.length }} sessions</p>
  <p v-else>Loading…</p>
</template>
```

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/demo/mounted | grep -o '<p>[^<]*</p>'
<p>Loading…</p>
```

**The server sends *Loading…***, and the number arrives only after the browser has run the page and
made the request itself. That is client-side rendering inside a Nuxt app,
with everything lesson 19 said against it. It is right for data that belongs to the browser, the way
lesson 19's `today` did, and wrong for data the server could have fetched.

Delete the demos:

```
ana@dev:~/vue/planner-nuxt$ rm -r app/pages/demo
```
