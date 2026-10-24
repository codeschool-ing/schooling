---
title: Pages, routes from files
version: 1
---

**A `.vue` file in `app/pages/` is a route, and its path in that folder is its address.** There is no
list to keep: `pages/index.vue` is `/`, `pages/about.vue` would be `/about`, and a part of the name in
square brackets is a parameter, so `pages/courses/[id].vue` is `/courses/:id`, the route lesson 12
wrote by hand. First `app.vue` swaps the welcome page for `<NuxtPage />`, the `<RouterView>` of Nuxt,
where the page of the current address is drawn:

```html
<!-- app/app.vue -->
<template>
  <NuxtRouteAnnouncer />
  <NuxtPage />
</template>
```

`<NuxtRouteAnnouncer>` was in the template already, and it stays. It is a region a screen reader reads
out, holding the page's title, so that a navigation that changes the page without loading a new one is
announced, the job lesson 12 did by setting `document.title` in `afterEach`. Then the two pages, short
for now; the last section of the lesson fills them in:

```html
<!-- app/pages/index.vue: the page at / -->
<template>
  <h1>This week</h1>
  <ul>
    <li><NuxtLink to="/courses/statistics">Statistics</NuxtLink></li>
    <li><NuxtLink to="/courses/spanish">Spanish</NuxtLink></li>
    <li><NuxtLink to="/courses/guitar">Guitar</NuxtLink></li>
  </ul>
</template>
```

```html
<!-- app/pages/courses/[id].vue: the page at /courses/statistics, /courses/spanish and so on -->
<script setup lang="ts">
const route = useRoute()
</script>

<template>
  <h1>The course {{ route.params.id }}</h1>
  <p><NuxtLink to="/">Back to the week</NuxtLink></p>
</template>
```

No `import` anywhere: `NuxtLink` and `useRoute` are there without one, which is the auto-imports
section. `<NuxtLink>` is `<RouterLink>` with more to it, and the second transcript below says what.

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text body
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of body
Study planner
This week
Statistics
Spanish
Guitar
```

*Study planner* above the heading is the route announcer: it is hidden from sight and not from
`innerText`.

## Navigating, and what was already fetched

Click a course, and watch the requests, leaving out the modules of Nuxt and Vue themselves:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --do 'click text=Spanish' --text body | grep -v '^net  GET /_nuxt/@'
net  GET /  200
net  GET /_nuxt/home/ana/vue/planner-nuxt/node_modules/nuxt/dist/app/entry.async.js  200
[vite] connecting...
[vite] connected.
net  GET /_nuxt/app.vue  200
net  GET /_nuxt/pages/index.vue  200
<Suspense> is an experimental feature and its API will likely change.
-- click text=Spanish
net  GET /_nuxt/pages/courses/[id].vue  200
== the text of body
Study planner
The course spanish

Back to the week
```

**The click asked for one file, the page's own code, `pages/courses/[id].vue`, and no new document**:
there is no second `GET /`, because the router changed the page in place, as the Vite planner's did.
Each page is a chunk of its own, loaded the first time it is needed. A `<NuxtLink>` also tries to be
earlier than the click: once the browser is idle, it fetches the code of every page a visible link
points to, which Nuxt calls *prefetching*. `look` clicked before the browser had an idle moment, so
here the request comes after `-- click`. A person reading the page gives the browser that moment long
before they click, so for them the request comes first, and the click has nothing left to wait for.

## The HTML comes from the server

The same address asked for with `curl`, which runs no JavaScript at all:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<h1>[^<]*</h1>'
<h1>The course spanish</h1>
```

**The heading is in the HTML the server sent.** In the Vite planner, `curl` of a course page would
have found an empty `<div id="app">` and nothing else, because the heading was drawn by JavaScript in
the browser. Here the server ran the page's component and sent what it drew. Lesson 19 is about what
that buys and what it costs; this section only needs to know it happens.

## An address with no page

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/courses/spanish/extra --text body
[error] Failed to load resource: the server responded with a status of 404 (Page not found: /courses/spanish/extra)
[vite] connecting...
[vite] connected.
[warn] [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
[warn] [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
<Suspense> is an experimental feature and its API will likely change.
== the text of body
404
Page not found: /courses/spanish/extra

Page not found: /courses/spanish/extra

Go back home
```

**A real 404, from the server**, the first line of the transcript, before any script ran, which the
Vite planner could not do: its server sent `index.html` for every address, and lesson 12's catch-all
route drew a *not found* page on a `200`. Nuxt knows its routes on the server, so it answers with the
right status. Vue Router warns that no route matches, in the browser's console and in the server's
terminal, and the page is Nuxt's own error page, which the next section replaces.

The dev server's terminal says how it took the change:

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
✔ Vite client built in 53ms
✔ Vite server built in 26ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1357ms
◆ Ready in 2.76s  → http://localhost:3000/
  config 255ms · modules 68ms · app 333ms · types 313ms · bundle 247ms · server 1.54s
(node:9550) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
ℹ hmr update /app.vue
[nuxt] ℹ Pages enabled
[nuxt] ℹ Pages enabled
(node:9693) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use `node --trace-warnings ...` to show where the warning was created)
ℹ Nuxt requested a restart. Reloading Nuxt...
ℹ Re-optimizing dependencies because vite config has changed
✔ Vite client built in 26ms
✔ Vite server built in 21ms
[nitro] ✔ Nuxt Nitro server built in 903ms
(node:9550) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
WARN  [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
WARN  [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
WARN  [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
WARN  [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
```

`hmr update /app.vue`, then, when the `pages` folder appeared, **`Pages enabled` and a restart**: a
project without `pages/` has no router at all, and adding the folder changes what Nuxt builds, so it
starts again on its own.
