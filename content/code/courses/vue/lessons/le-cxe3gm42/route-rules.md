---
title: Route rules, a mode per page
version: 1
---

**`routeRules` in `nuxt.config.ts` gives each address its own way of being rendered, in one project.**
The planner's week needs the server every time, the `about` page would be the same file for every
reader forever, and the course pages sit in between: they change when a session is ticked, and
nobody minds if a minute passes first. The planner gets an `about` page:

```html
<!-- app/pages/about.vue: the page at /about, the same for everybody -->
<template>
  <h1>About the planner</h1>
  <p>
    The study planner keeps the sessions of three courses, a week at a time. It is the project of the
    vue course, built twice: once with Vite and Vue Router, once with Nuxt.
  </p>
</template>
```

and three rules, one per kind:

```typescript
// nuxt.config.ts: the study planner, made by Nuxt.
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  // Off, as lesson 1 left Vue's: a button and requests of their own in every page.
  devtools: { enabled: false },
  css: ['~/assets/main.css'],
  app: {
    head: { htmlAttrs: { lang: 'en' }, title: 'Study planner' },
  },
  routeRules: {
    // Drawn once, by the build: nothing on it changes between two deploys.
    '/about': { prerender: true },
    // Drawn by the server at most once a minute; the copy is served meanwhile.
    '/courses/**': { swr: 60 },
    // No cache between the server and the browser may keep an answer of the API.
    '/api/**': { headers: { 'cache-control': 'no-store' } },
  },
})
```

`prerender: true` is the static generation of the last section, for one page, inside a normal build.
`swr: 60` is *stale-while-revalidate*: the server renders the page once, keeps the HTML, and for the
next sixty seconds answers from that copy; the first request after that still gets the old copy, at
once, and makes the server render a new one in the background. Nuxt's `isr`, *incremental static
regeneration*, is the same idea carried out by the hosts that support it, which keep the copy in their
own network rather than in the server. `headers` sets response headers, here one telling every cache on
the way not to keep what the API answers. Build:

```
ana@dev:~/vue/planner-nuxt$ npm run build 2>&1 | grep -i prerender
[nitro] ℹ Initializing prerenderer
[nitro] ℹ Prerendering 1 routes
[nitro] ℹ Prerendered 2 routes in 1.688 seconds
ana@dev:~/vue/planner-nuxt$ ls .output/public
_nuxt
about
favicon.ico
robots.txt
```

**`about` is now a folder of `.output/public`**, a file a static host or a CDN can send without asking
the server. The other rules are carried out by the server at run time. Start it, and read the headers:

```
ana@dev:~/vue/planner-nuxt$ curl -s -D - -o /dev/null http://localhost:3000/api/courses | grep -i cache-control
cache-control: no-store
ana@dev:~/vue/planner-nuxt$ curl -s -D - -o /dev/null http://localhost:3000/courses/spanish | grep -i cache-control
cache-control: s-maxage=60, stale-while-revalidate
```

The API says `no-store`, and the course page `s-maxage=60, stale-while-revalidate`, the instruction
that lets a cache in front of the server, a CDN's, do the same keeping.

## Sixty seconds of the old page

Count the ticked boxes on the Spanish page, tick its other session, and count again:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l
1
ana@dev:~/vue/planner-nuxt$ curl -s -w '\n' -X PATCH http://localhost:3000/api/sessions/s6
{"id":"s6","course":"spanish","date":"2026-10-23","minutes":40,"done":true}
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l
1
```

**Still one.** The tick is in the server's data, and the page came from the copy rendered before it.
After the minute is up:

```
ana@dev:~/vue/planner-nuxt$ sleep 60
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l
1
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l
2
```

**The first request after the minute got the old copy, and the second the new one**: the first set off
the new render and did not wait for it. That is the trade `swr` makes on purpose, a fast answer that
is at most a minute and one request out of date, and it is the wrong trade for a page whose reader has
just changed it. A student who ticks a session on the course page and reloads it sees the tick gone;
the browser's own copy, hydrated and refreshed by `useFetch`, is right, but the HTML is not. On the
planner, `swr` belongs on pages that many people read and few change, and the course pages are not
those. The rule stays for the rest of this lesson, to be argued with in the last section.

## A rule is not a lock

Route rules decide how a page is rendered and cached. **They are not the place for anything that has
to hold**. Nuxt published an advisory, GHSA-vjh5-4x84-xrqp, that route rules, the `headers` and
`redirect` kinds included, were skipped when an address was written with different capitals,
`/API/courses` for `/api/courses`, on servers that treat the two as one; it covers every Nuxt up to
4.6.1, which is one more reason lesson 18 installed 4.6.2.
The lesson to keep is the general one: a header that protects something, a redirect away from a
private page, needs to be enforced by the code that serves the thing, or by the host, and not only
by a pattern that matches its address.

`ssr: false` is the last rule worth knowing: that address is sent as an empty shell and drawn in the
browser, the Vite planner's way, for a page that has nothing to gain from the server.
