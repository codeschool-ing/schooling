---
title: Layouts, the frame around the pages
version: 1
---

**A layout is a component with a `<slot />` where the page goes, kept in `app/layouts/`.** The Vite
planner's `App.vue` drew a header, the `<RouterView>` and a footer, and every page appeared inside that
frame. In Nuxt the frame is a layout, `app.vue` says where layouts are drawn, and a page may pick a
different one. `app/layouts/default.vue` is the one every page gets unless it asks otherwise:

```html
<!-- app/layouts/default.vue: the frame around every page. -->
<script setup lang="ts">
import { version } from 'vue'
</script>

<template>
  <header>
    <p class="brand"><NuxtLink to="/">Study planner</NuxtLink></p>
  </header>
  <main>
    <slot />
  </main>
  <footer>
    <p>Built with Vue {{ version }}, by Nuxt</p>
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

`version` is still imported: auto-imports cover Nuxt's functions and Vue's own composition functions,
`ref`, `computed` and the rest, but not every name the `vue` package exports. `app.vue` puts the
page inside the layout:

```html
<!-- app/app.vue -->
<template>
  <NuxtRouteAnnouncer />
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>
```

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text body
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of body
Study planner

Study planner

This week
Statistics
Spanish
Guitar

Built with Vue 3.5.44, by Nuxt
```

**The header and the footer came from the layout, the heading and the list from the page**; the first
*Study planner* is the route announcer of the last section. A page
that wants another frame names it, `definePageMeta({ layout: 'print' })` for a
`layouts/print.vue`, and `layout: false` for none at all. The planner needs only the one.

## The error page

When a route is missing, or a page throws an error, Nuxt draws `app/error.vue` instead of the page,
on the server and in the browser, and with the right HTTP status. It is a component of its own, outside
the pages, so it does not get the layout unless it asks for it with `<NuxtLayout>`:

```html
<!-- app/error.vue: what Nuxt draws in place of a page that does not exist or failed. -->
<script setup lang="ts">
import type { NuxtError } from '#app'

const { error } = defineProps<{ error: NuxtError }>()
</script>

<template>
  <NuxtLayout>
    <h1>{{ error.statusCode === 404 ? 'Nothing here' : 'Something went wrong' }}</h1>
    <p>{{ error.statusMessage }}</p>
    <p><button @click="clearError({ redirect: '/' })">Back to this week</button></p>
  </NuxtLayout>
</template>
```

`#app` is Nuxt's own module of types and functions, where `NuxtError` lives. `clearError` is
auto-imported, and it is a button rather than a link on purpose: it ends the error state as well as
leaving the address, so the next page is drawn normally. Ask for the missing page again:

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
Study planner

Nothing here

Page not found: /courses/spanish/extra

Back to this week

Built with Vue 3.5.44, by Nuxt
```

**The planner's own frame, around the message Nuxt wrote for the missing route**, and still a `404`
underneath.
