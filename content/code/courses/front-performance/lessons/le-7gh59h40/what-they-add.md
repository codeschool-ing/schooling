---
title: What a meta-framework adds
version: 1
---

**A meta-framework is the server half of lesson 1, written once for everybody, around one UI
framework.** React's is Next.js, Vue's is Nuxt and Svelte's is SvelteKit. Angular has no separate
product with its own name: its server rendering is `@angular/ssr`, maintained by the Angular team
and switched on with one flag when a project is made, and it does the same job. This lesson calls
all four meta-frameworks, for want of a better word.

You took one of the four frameworks before this course. **You do not need the other three to
follow this lesson**, and nothing here assumes which one you took: each section shows the same
two pages of the planner in one of them, briefly, and the comparison is in the sections around
them. Read the one you know closely and the others for their shape.

## What lesson 1 did by hand

Everything a meta-framework does, the planner already did in a few lines. The table is the map
from one to the other:

| in lesson 1 | what it did | what a meta-framework gives you instead |
|---|---|---|
| `page(plan, path)` | decided from the address which page to draw | a **router**, filled in from files in a folder or from a list of routes |
| `server.ts` | drew the page on each request and served the files | a **production server**, built for you, or a set of static files |
| `mount` and its link handler | took over in the browser, drew the next page without asking the server | **hydration** and **client-side navigation**, on by default |
| `fetch("/courses.json")` and the server's `readFile` | loaded the data, once in each place | a **loader**: a function that runs on the server for a route, whose result reaches the browser with the page |
| `npm run build` | bundled the script | a build that also decides, per route, whether to render now, at build time or in the browser |

Two more things come with them that the planner never needed: a development server that reloads
both halves as you edit, and conventions for everything around a page, such as its `<title>`, a
page for an address that does not exist, an error page, and a layout shared by several routes.

## What they cost

They are not free, and the price is worth naming before the four sections that follow:

- **JavaScript.** Each one ships its UI framework and its router to the browser, on every page
  that hydrates. The section "The same page, four ways" weighs it for one page.
- **A server to run**, unless every page is built ahead of time. A Node process that has to stay
  up, be updated and be watched.
- **Their own rules.** Where code runs, which file is the server's and which the browser's, what
  may be cached and for how long: each answers these differently, and the answers change between
  major versions. Next.js 16, the version in this lesson, prints a warning in its own files that
  its APIs differ from older versions, and they do.

**What they buy is everything in the left-hand column done correctly for an app of any size**,
including the parts lesson 1 got away without: an address that does not exist, a route with a
parameter, data a page needs before it can render, and a page that renders on the server for some
addresses and is built ahead for others.
