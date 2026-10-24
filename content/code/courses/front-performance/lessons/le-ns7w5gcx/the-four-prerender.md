---
title: The same pages, prerendered four ways
version: 1
---

**Each meta-framework does what `prerender.ts` did, and the evidence is the same in all four: after
the build, there is an HTML file for every page.** Lesson 2's section "Rendering mode, per route"
showed where each one keeps the switch. Here each project from `~/meta` throws it, builds, and
lists the files. The listing is the thing to compare; the build logs are long and say the same.

## Next.js: nothing to change

The Next.js project already prerendered its pages in lesson 2, because everything they read is
cached. Its HTML files are inside `.next/`, where `next start` serves them from:

```
ana@dev:~/meta/next$ npm run build >/dev/null 2>&1; find .next/server/app -name '*.html' | sort
.next/server/app/_global-error.html
.next/server/app/_not-found.html
.next/server/app/courses/[slug].html
.next/server/app/courses/git.html
.next/server/app/courses/html-css.html
.next/server/app/courses/javascript.html
.next/server/app/index.html
```

One file per course, one for the home page, `_not-found.html` and `_global-error.html` for the two
pages Next.js always has, and `[slug].html`: the shell of the `◐` line, served for a slug the build
did not list while the rest of that page is rendered.

## Nuxt: `nuxt generate`

Nuxt can prerender a route with `routeRules`, or the whole site with one command. `npm run
generate`, which the maker put in `package.json`, builds the app, starts it, and **crawls it**: it
renders `/`, follows every link it finds, and renders those, until no new address turns up.

```
ana@dev:~/meta/nuxt$ npm run generate >/dev/null 2>&1; find .output/public -name '*.html' | sort
.output/public/200.html
.output/public/404.html
.output/public/courses/git/index.html
.output/public/courses/html-css/index.html
.output/public/courses/javascript/index.html
.output/public/index.html
```

The crawler found the three course pages by following the links of the home page; nothing listed
them. Beside each page Nuxt also wrote a `_payload.json`, the data that page was rendered from,
which the browser fetches instead of the page when it navigates there with a click. `200.html` is
the empty shell, for a host to use as the fallback of an app that renders in the browser, and
`404.html` is the page for any other address.

**A crawler only finds what is linked.** A course nobody links to is not generated, and nothing
fails; `nitro.prerender.routes` in `nuxt.config.ts` lists such addresses by hand.

## SvelteKit: one line in a layout

`export const prerender = true` in a layout applies to every route below it. Save this as
`src/routes/+layout.server.ts`; it is a new file, beside the `+layout.svelte` the maker wrote:

```typescript
// src/routes/+layout.server.ts: every route below this layout is built at build time.
export const prerender = true;
```

SvelteKit's prerenderer also crawls, from `/`:

```
ana@dev:~/meta/svelte$ npm run build >/dev/null 2>&1; find build/prerendered -name '*.html' | sort
build/prerendered/courses/git.html
build/prerendered/courses/html-css.html
build/prerendered/courses/javascript.html
build/prerendered/index.html
```

**The pages are `git.html`, not `git/index.html`**, which is SvelteKit's default for an address
without a trailing slash. Its own Node server finds them. A plain static host may not: some answer
`/courses/git` with `git.html`, some only with `git/index.html`, and `trailingSlash` in a layout
switches SvelteKit to the second shape.

## Angular: `RenderMode.Prerender`, with the slugs

Angular does not crawl. A route with a parameter is prerendered for exactly the values
`getPrerenderParams` returns, which run at build time, in Node, so they can read the file directly.
Replace `src/app/app.routes.server.ts`:

```typescript
// src/app/app.routes.server.ts: how the server renders each address.
import { readFile } from "node:fs/promises";
import { RenderMode, ServerRoute } from "@angular/ssr";
import type { Plan } from "./plan";

export const serverRoutes: ServerRoute[] = [
  { path: "", renderMode: RenderMode.Prerender },
  {
    path: "courses/:slug",
    renderMode: RenderMode.Prerender,
    async getPrerenderParams() {
      const plan: Plan = JSON.parse(await readFile("public/courses.json", "utf8"));
      return plan.courses.map((c) => ({ slug: c.slug }));
    },
  },
  { path: "**", renderMode: RenderMode.Server },
];
```

The last line keeps every other address rendered on request, so a slug the build did not know is
still answered by the server. Build and list:

```
ana@dev:~/meta/angular$ npm run build 2>&1 | grep Prerendered; find dist/angular/browser -name '*.html' | sort
Prerendered 4 static routes.
dist/angular/browser/courses/git/index.html
dist/angular/browser/courses/html-css/index.html
dist/angular/browser/courses/javascript/index.html
dist/angular/browser/index.csr.html
dist/angular/browser/index.html
```

`index.csr.html` is the empty shell, which the server falls back to when it cannot render, as it
did in lesson 2 for the host it refused.

## Four shapes of the same result

| | how the addresses were found | where the files are | a course page is |
|---|---|---|---|
| your `prerender.ts` | read from `courses.json` | `dist/` | `courses/git/index.html` |
| Next.js | `generateStaticParams` | `.next/server/app/` | `courses/git.html` |
| Nuxt | crawled from `/` | `.output/public/` | `courses/git/index.html` |
| SvelteKit | crawled from `/` | `build/prerendered/` | `courses/git.html` |
| Angular | `getPrerenderParams` | `dist/angular/browser/` | `courses/git/index.html` |

**Listing the addresses and crawling for them fail differently.** A list misses a page somebody
forgot to add to it; a crawler misses a page nobody linked to. Both fail in silence, with a build
that succeeds, and both are checked the same way: count the files the build wrote against the
pages the data says exist.
