---
title: Hydrating less of the page
version: 1
---

**Most of a page never changes after it arrives, and hydrating it is work for nothing.** The
planner's course page has a heading, two dates and a link that a script never needs to touch, and two
buttons and a form that it does. The ideas in this section all start from that observation, and each
draws the line in a different place.

## Islands

**An island is a part of a static page that hydrates on its own, and everything around it is HTML
with no script at all.** The page is rendered on the server as usual. Only the components marked as
interactive ship JavaScript, and each one hydrates independently, so a slow island does not hold back
a fast one. Astro is the framework best known for it; the planner's buttons and form would be two
islands in a page of plain HTML.

## Server components

**React Server Components draw the same line inside a React app.** A server component runs only on
the server and sends its result, never its code; only components marked `"use client"` are sent to
the browser and hydrated. Lesson 2's Next.js project was made entirely of server components, so there
was nothing of the app's own to hydrate, and still the page ran React and Next.js's router, which is
the price of being able to navigate without reloading.

## Hydrating later

**Some parts of a page can wait to be hydrated until they are needed**: when they scroll into view,
when the browser is idle, or when somebody first interacts with them. Angular calls this incremental
hydration, written as `@defer` with a `hydrate` trigger, such as `@defer (hydrate on viewport)`, once
`withIncrementalHydration()` is added beside the event replay of lesson 2. Nuxt offers the same with
attributes on a lazily loaded component, such as `hydrate-on-visible`. Until its trigger fires, the
part is server HTML, as dead as in the window of two sections ago, which is why these features pair
with event replay.

## Resuming instead of replaying

**Resumability skips hydration altogether.** The server writes into the page enough about the state
of every component that the browser never needs to run them again; a handler's code is fetched only
when its event fires. Qwik is built on it. The cost moves rather than disappears: the first click on
each control waits for that control's code.

## For the planner

None of this needs a framework to understand. The planner already hydrates almost nothing: one
listener on the container, and a comparison of text. A plain app is close to the smallest hydration
there is, which is part of why it is the app this course measures.
