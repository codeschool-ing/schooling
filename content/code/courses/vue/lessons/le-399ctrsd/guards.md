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
a page loads, but a change made by the router, with no page load, is not reliably announced: telling a
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

Old code writes guards with a third argument, `next`, and calls `next()` to continue. Version 5
still runs it, with a deprecation warning in development, and it is easy to get wrong, since forgetting to call it leaves the navigation hanging; returning a value
does the same job, and is what this course writes.

The guard here fetches `courses.json` a second time, beside `App`'s own load, because a guard runs
outside any component and cannot inject `App`'s data. That duplication is the cue for lesson 13: a
store is a module, importable from a guard as well as from a component.
