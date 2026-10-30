---
title: Rendering mode, per route
version: 1
---

**Each of the four lets one route be built ahead of time, another rendered per request and a third
left to the browser, in the same app.** Lesson 1's section "Choosing, one page at a time" argued
that this is the choice that matters; here is how each one spells it. Lesson 3 builds the planner's
pages ahead of time in all four and watches the files appear, so this section only shows where the
switch is.

| | built ahead of time | rendered on each request | left to the browser |
|---|---|---|---|
| **Next.js 16** | the default for a page whose data is cached (`"use cache"`), with `generateStaticParams` listing a parameter's values | anything that reads `cookies()`, `headers()`, `connection()` or uncached data, inside `<Suspense>` | a `"use client"` component that fetches its own data in the browser |
| **Nuxt 4** | `routeRules: { "/": { prerender: true } }` in `nuxt.config.ts` | the default | `routeRules: { "/settings/**": { ssr: false } }` |
| **SvelteKit 3** | `export const prerender = true;` in the route's `+page.ts`, `+page.server.ts` or a layout | the default | `export const ssr = false;` |
| **Angular 21** | `RenderMode.Prerender` in `app.routes.server.ts`, with `getPrerenderParams` for a parameter | `RenderMode.Server` | `RenderMode.Client` |

Three of them render on each request unless told otherwise, and **Next.js decides from what the
page reads**. That difference is the one most likely to surprise you when moving between them: in
Next.js 16 the course pages of this lesson were built at build time without a line saying so,
because everything they read was cached, and adding one uncached read to a page changes how it is
rendered without any change to the page's configuration.

## Where the decision sits

In Nuxt and Angular the decision is in **one file for the whole app**, a list of address patterns
with a mode each. You can read the site's rendering in one place, and a page's own file does not
say how it is rendered. In SvelteKit the decision is **in the route itself**, an `export` beside its
`load`, and a layout's value applies to every route below it. In Next.js it **follows from the
code**, which keeps the page and its rendering together and makes the build's route table, the one
`next build` printed, the place to read the outcome.

Nuxt's route rules also hold what lesson 3 needs: `isr` and `swr` regenerate a page in the
background after a given number of seconds, and lesson 3 runs them. SvelteKit and Angular leave
regeneration to whatever caches the page in front of the server; Next.js has it built in, as
`cacheLife` already showed.

## Two modes that are easy to confuse

**"Left to the browser" is not the same as "not prerendered".** A route left to the browser sends
the empty shell of lesson 1, and everything is drawn by the script. A route rendered on each
request sends the finished page. Both are "not built ahead of time", and they sit at the two ends of
the table in lesson 1's first section.

**And prerendered does not mean no JavaScript.** A prerendered page still ships the framework and
hydrates, exactly like a server-rendered one; only the moment the HTML was made has moved. SvelteKit
can drop the JavaScript from a page entirely, with `export const csr = false;`. The other three can
make less of a page hydrate, in ways lesson 4 comes to, but each still sends its runtime: the pages
of this lesson in Next.js are made only of server components, and they ran the most JavaScript of
the four in the section "The same page, four ways".
