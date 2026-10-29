---
title: The application frameworks, and the form with JavaScript off
version: 1
---

**Each of the four has an application framework around it, and they look more alike than the
libraries do.** SvelteKit, Next.js for React, Nuxt for Vue, and Angular's own router with its server
rendering all route by file or by configuration, load data on the server, render the first page there
and take over in the browser. Lessons 12 to 17 of this course map onto them closely:

| SvelteKit | Next.js | Nuxt | Angular |
|---|---|---|---|
| a folder with `+page.svelte` | a folder with `page.tsx` | a file in `pages/` | a route in the router's configuration |
| `+layout.svelte` | `layout.tsx` | a layout in `layouts/` | a parent route with a `<router-outlet>` |
| `load` in `+page.server.js` | an async Server Component | `useFetch`, `useAsyncData` | a resolver, or a service called by the component |
| form actions | Server Actions | server routes in `server/` called with `$fetch` | `HttpClient` to an API |
| `+server.js` | `route.ts` | `server/api/` | a separate back end |
| `ssr`, `csr`, `prerender` | static, dynamic and streaming rendering | `ssr`, `routeRules` | SSR and prerendering with hydration |

The React course covers Server Components in lesson 15, Actions in lesson 16 and Next.js in lesson 18;
the Vue course covers Nuxt in lessons 18 to 20; the Angular course covers its router in lessons 17 and 18
and server rendering in lesson 23.

## The row that differs

**The forms row is where SvelteKit stands out**, and it is why lesson 14 was the longest in this course.
A SvelteKit form action is a `<form>` that the browser sends by itself, so it works with JavaScript off,
and `use:enhance` makes it better when JavaScript is there. Of the others, React has come closest:
Server Actions in Next.js accept a form the same way, a `<form action={…}>` that the server handles,
and Next.js renders them so that they can be submitted before the page's JavaScript has loaded. Nuxt
and Angular take data to the server with JavaScript, from code in the page: in both, a form that works
with JavaScript off is possible, and is something you build rather than what you get.

That is a difference of default, not of capability. Any of the four can build a planner that works
without JavaScript, and any of them can build one that does not. The default decides which one most
projects end up with, and lesson 14's planner is what SvelteKit's default produces.
