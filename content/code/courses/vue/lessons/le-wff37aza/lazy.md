---
title: Lazy, and what to show while waiting
version: 1
---

**By default a navigation waits for the next page's `useFetch`: the router does not show the page
until its data has arrived.** On the planner's own server that wait is a few milliseconds and nobody
sees it. On a slow API it is a click that seems to do nothing. To see it, make the course route slow,
two seconds before it answers:

```
ana@dev:~/vue/planner-nuxt$ sed -i 's#defineEventHandler((event) => {#defineEventHandler(async (event) => {\n  await new Promise((resolve) => setTimeout(resolve, 2000))#' 'server/api/courses/[id].get.ts'
```

Click a course, and read the heading a moment later:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --do 'click text=Spanish' --text 'main h1'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
-- click text=Spanish
== the text of main h1
This week
```

**Still *This week***: the click happened, and the old page stays for the two seconds the new one
waits. `lazy: true` changes that. The navigation goes ahead at once and the data follows:

```
ana@dev:~/vue/planner-nuxt$ sed -i 's#useFetch(() => `/api/courses/${route.params.id}`)#useFetch(() => `/api/courses/${route.params.id}`, { lazy: true })#' 'app/pages/courses/[id].vue'
```

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --do 'click text=Spanish' --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
-- click text=Spanish
== the text of main
Goal: minutes a week
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --do 'click text=Spanish' --do 'wait 2500' --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
-- click text=Spanish
-- wait 2500
== the text of main
Spanish

Goal: 120 minutes a week

 19 October 2026, Spanish, 30 minutes
 23 October 2026, Spanish, 40 minutes
```

**The course page at once, with nothing in it**, and two seconds later the course. Neither way is good
on its own: waiting looks like a click that did nothing, and lazy looks empty for as long as the
request lasts, with
`Goal: minutes a week` saying so. Lazy is only half of a decision; the other half is a template that
uses `status`:

```html
<p v-if="status === 'pending'">Loading the course…</p>
```

`useLazyFetch(url)` is the same as `useFetch(url, { lazy: true })`. One more option often goes with
it, `server: false`, which skips the fetch during the server's render altogether: the page arrives
without the data and the browser fetches it, which is lesson 19's client-only, applied to one piece of
data.

## The planner's choice

The planner stays as it is, not lazy: its server answers in milliseconds, so waiting costs nothing, and
a page that arrives complete has no loading state to design. Put both files back:

```
ana@dev:~/vue/planner-nuxt$ sed -i 's#, { lazy: true })#)#' 'app/pages/courses/[id].vue'
ana@dev:~/vue/planner-nuxt$ sed -i '/setTimeout(resolve, 2000)/d; s#async (event)#(event)#' 'server/api/courses/[id].get.ts'
```

When the data comes from somewhere slow, a third-party API, a report that takes seconds to compute,
lazy with a real loading state is the better trade, and so, sometimes, is not fetching it during the
server's render at all. The questions are the same as for rendering in lesson 19: what must the page
show the moment it appears, and what can follow.
