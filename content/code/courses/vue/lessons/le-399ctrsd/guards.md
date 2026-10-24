---
title: Guards, and the address that leads nowhere
version: 1
---

**A navigation guard is a function the router calls during a navigation, which can let it go ahead,
send it somewhere else, or cancel it.** It is the router's place for decisions that depend on where
the student is going: is this page allowed, does this course exist, should the title change. The
planner uses two kinds, one before entering a route and one after every navigation.

## Before entering: does the course exist?

`/courses/latin` matches `/courses/:id` perfectly well, and without a check the course page would draw
a heading that says `latin` over *Nothing planned this week.*, a page that looks like a course with
nothing planned.
The course route's `beforeEnter` guard asks first:

```javascript
beforeEnter: async (to) => {
  if (!(await courseExists(to.params.id))) {
    return { name: 'not-found', params: { pathMatch: to.path.slice(1).split('/') } }
  }
},
```

**What a guard returns decides the navigation**: nothing, or `true`, lets it continue; a location, as
here, redirects there instead; `false` cancels it and leaves the student where they were. A guard can
be `async`, and the router waits for it, so it may fetch something first. The redirect keeps the path
the student typed, so the not-found page can say what was not found:

```html
<!-- src/views/NotFound.vue -->
<script setup>
import { RouterLink, useRoute } from 'vue-router'

const route = useRoute()
</script>

<template>
  <h1>Not found</h1>
  <p>Nothing in the planner lives at {{ route.fullPath }}.</p>
  <p><RouterLink to="/">Back to this week</RouterLink></p>
</template>
```

```
ana@dev:~/vue/planner$ look http://localhost:5173/courses/latin --text main
[vite] connecting...
[vite] connected.
== the text of main
Not found

Nothing in the planner lives at /courses/latin.

Back to this week
```

And an address that matches no route at all lands on the same page, through the last route, the one
whose path matches everything:

```
ana@dev:~/vue/planner$ look http://localhost:5173/nowhere/at/all --text '#app'
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

6 sessions, read from courses.json

Not found

Nothing in the planner lives at /nowhere/at/all.

Back to this week

Built with Vue 3.5.44
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three addresses on the left and where each one ends. /courses/spanish and /courses/latin both match the route /courses/:id, whose beforeEnter guard asks whether the course exists. For spanish it does, and the navigation continues to the course page. For latin it does not, and the guard returns the location of not-found, so the navigation is redirected to NotFound.vue, which keeps the path that was typed. /nowhere/at/all matches no route but the last, whose path matches everything, and lands on the same NotFound.vue.\"><rect x=\"20\" y=\"36\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/spanish</text><rect x=\"20\" y=\"96\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/latin</text><rect x=\"20\" y=\"176\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/nowhere/at/all</text><rect x=\"220\" y=\"55\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/courses/:id</text><rect x=\"380\" y=\"50\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">beforeEnter</text><text x=\"450\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">does the course exist?</text><rect x=\"220\" y=\"170\" width=\"300\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"370\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the last route: its path matches everything</text><rect x=\"570\" y=\"24\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the course page</text><rect x=\"570\" y=\"140\" width=\"130\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">NotFound.vue</text><text x=\"635\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">keeps the typed path</text><line x1=\"172\" y1=\"51\" x2=\"216\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"216.0,68.0 208.0,68.3 210.2,62.4\" fill=\"var(--wire)\"></polygon><line x1=\"172\" y1=\"111\" x2=\"216\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"216.0,88.0 210.9,94.2 208.0,88.7\" fill=\"var(--wire)\"></polygon><line x1=\"352\" y1=\"77\" x2=\"376\" y2=\"77\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"376.0,77.0 368.6,80.1 368.6,73.9\" fill=\"var(--wire)\"></polygon><line x1=\"522\" y1=\"60\" x2=\"566\" y2=\"44\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"566.0,44.0 560.1,49.4 558.0,43.6\" fill=\"var(--phosphor)\"></polygon><text x=\"536\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">yes</text><line x1=\"522\" y1=\"96\" x2=\"590\" y2=\"137\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"590.0,137.0 582.1,135.9 585.3,130.5\" fill=\"var(--amber)\"></polygon><text x=\"548\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no: redirect</text><line x1=\"172\" y1=\"191\" x2=\"216\" y2=\"191\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"216.0,191.0 208.6,194.1 208.6,187.9\" fill=\"var(--wire)\"></polygon><line x1=\"522\" y1=\"191\" x2=\"566\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"566.0,180.0 559.6,184.8 558.1,178.8\" fill=\"var(--wire)\"></polygon></svg>", "caption": "A guard's return value decides the navigation; an address no route takes ends on the same page."}
```

**An unknown address is never shown as the week.** That is the router's half of the rule lesson 2 met
in the dev server: a wrong address should say it is wrong, not show something that looks fine.

## After every navigation: the title

`router.afterEach` runs after every navigation, including one a guard cancelled or redirected, and
receives what went wrong, if anything, as its third argument. The planner uses it to set the tab's
title from the route's `meta`, and only when nothing went wrong:

```
ana@dev:~/vue/planner$ look http://localhost:5173/courses/spanish --html title --text -
[vite] connecting...
[vite] connected.
== the HTML of title
<title>Course · Study planner</title>
```

A browser tab says which page it is, and so does the history list and a bookmark; an application that
never updates the title is one where every page has the same name. A screen reader reads the title when
a page loads, but a change made by the router, with no page load, is not reliably announced. Telling a
blind student the page changed takes moving the focus to the new page's heading, or a live region, and
`front-quality` lesson 12 covers both.

## The guards you will meet

| guard | runs | typical use |
|---|---|---|
| `router.beforeEach(fn)` | before every navigation | "must be signed in": redirect to a sign-in page |
| `beforeEnter` on a route | before entering that route, not when only its params change | checking that a parameter names something real |
| `router.afterEach(fn)` | after every navigation, with the failure, if any, as its third argument | titles, analytics, moving focus to the new page's heading |
| `onBeforeRouteLeave` in a view | before leaving that view | "you have unsaved changes": ask, and return `false` to stay |

The second row has a catch the planner lives with: going from `/courses/spanish` to `/courses/latin`
with a link only changes a parameter, so `beforeEnter` does not run. The planner only ever links to
courses that exist, and an address typed into the bar is a fresh entry, which does run it; an
application that links to user-typed values would check in `beforeEach` instead.

Old code writes guards with a third argument, `next`, and calls `next()` to continue. Version 5 still
runs it, with a deprecation warning in development, and it is easy to get wrong, since forgetting to
call it leaves the navigation hanging; returning a value does the same job, and is what this course
writes.

The guard here fetches `courses.json` a second time, beside `App`'s own load, because a guard runs
outside any component and cannot inject `App`'s data. That duplication is the cue for lesson 13: a
store is a module, importable from a guard as well as from a component.
