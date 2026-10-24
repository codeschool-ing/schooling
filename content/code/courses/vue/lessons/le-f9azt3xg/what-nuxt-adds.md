---
title: What Nuxt adds to Vue
version: 1
---

**Nuxt is Vue, Vite and a server, put together by a set of conventions about where files go.** Every
lesson so far has written by hand something Nuxt does from the name of a folder. Lesson 12 wrote
`router.ts`, a list of routes, each one an address and a component to import. Every component since
lesson 6 opens with `import` lines naming the components and functions it uses. Lesson 17 configured
Vite. In a Nuxt project:

| you write | Nuxt makes of it |
| --- | --- |
| a file in `app/pages/` | a route, its address taken from the file's path: `pages/courses/[id].vue` is `/courses/:id` |
| a file in `app/layouts/` | a frame the pages are drawn inside, the header and footer the planner's `App.vue` drew |
| a file in `app/components/` | a component every template may use without importing it |
| a function in `app/composables/`, `app/utils/` or `shared/utils/` | a function every script may call without importing it |
| a file in `server/api/` | an endpoint of a real HTTP server, `server/api/courses.get.ts` answering `GET /api/courses` |

There is still a router underneath, Vue Router 5, the one lesson 12 used, and Vite is still the dev
server and the build. What changes is that the list of routes is generated, and that the project now
has a server of its own, called **Nitro**, which serves the API and, by default, **renders every page
on the server before the browser gets it**.

That last one is the biggest change, and lesson 19 is about it. A page in the planner so far arrived
as an empty `<div id="app">` and was drawn by JavaScript in the browser; a Nuxt page arrives with its
HTML already in it, and the browser's copy of Vue then takes over the elements it was sent. Lesson 20
is about the part that follows from it, fetching data in a component that runs twice, once on the
server and once in the browser.

## What this lesson builds

A second planner, `~/vue/planner-nuxt`, beside the first. The first one stays as lesson 17 left it,
because lesson 21 tests it. The Nuxt one reuses its rules, `planner.ts`, unchanged, and three of its
components with a few lines removed, and it gets its data from its own server instead of a file in
`public`. By the end of the lesson it shows the week and a course, and ticking a session is a
request to the server, which keeps the change while it runs.

`front-performance` lesson 2 comes back to this from the other side, with Next, SvelteKit and
Angular's server rendering beside Nuxt. This lesson and the next two are Nuxt in depth; that one is
the comparison.
