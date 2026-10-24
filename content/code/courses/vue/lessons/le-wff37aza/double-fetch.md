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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 235\" role=\"img\" aria-label=\"One visit to /demo/twice, in time order from left to right, on two rows. On the server: first the layout&#x27;s session-count fetches GET /api/courses; then the page&#x27;s $fetch fetches GET /api/courses; then the server draws 6 sessions and sends the HTML. In the browser: the same setup runs again to hydrate, and the same $fetch, knowing nothing about payloads, fetches GET /api/courses a third time. The server&#x27;s terminal prints one line for each of the three.\"><text x=\"20\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">server</text><text x=\"20\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">browser</text><rect x=\"90\" y=\"40\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"162\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GET /api/courses</text><text x=\"162\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the layout's session-count</text><text x=\"162\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><rect x=\"240\" y=\"40\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"312\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GET /api/courses</text><text x=\"312\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the page's $fetch</text><text x=\"312\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2</text><rect x=\"390\" y=\"40\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">draws 6 sessions</text><text x=\"462\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sends the HTML</text><rect x=\"410\" y=\"140\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"482\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">runs the same setup</text><text x=\"482\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">to hydrate</text><rect x=\"565\" y=\"140\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"637\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GET /api/courses</text><text x=\"637\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the same $fetch, again</text><text x=\"637\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3</text><line x1=\"462\" y1=\"88\" x2=\"462\" y2=\"136\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"462.0,136.0 458.9,128.6 465.1,128.6\" fill=\"var(--wire)\"></polygon><text x=\"472\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTML</text><line x1=\"557\" y1=\"163\" x2=\"561\" y2=\"163\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"561.0,163.0 553.6,166.1 553.6,159.9\" fill=\"var(--wire)\"></polygon><line x1=\"90\" y1=\"212\" x2=\"710\" y2=\"212\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"710.0,212.0 702.6,215.1 702.6,208.9\" fill=\"var(--wire)\"></polygon><text x=\"400\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one visit, three lines of api: GET /api/courses in the server's terminal</text></svg>", "caption": "Plain $fetch in setup runs on both sides, so the browser asks again for what the server already drew."}
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
