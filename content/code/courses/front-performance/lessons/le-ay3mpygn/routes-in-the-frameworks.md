---
title: Routes in the frameworks
version: 1
---

**A route is the natural place to split**, because a person is on one page at a time. Three of the four
frameworks of lesson 2 split by route without being asked; one has to be told.

| | by route | a part of a page |
|---|---|---|
| **Next.js** | every page and layout in `app/` is its own chunk | `next/dynamic`, or React's `lazy` with `<Suspense>` |
| **Nuxt** | every file in `pages/` is its own chunk | a component named with the `Lazy` prefix, `<LazyChart>`, is loaded when it is first drawn |
| **SvelteKit** | every `+page` and `+layout` is its own chunk, which the build calls a node | `import()` inside the component, as in this lesson |
| **Angular** | only routes written with `loadComponent` | `@defer`, lesson 4's, which loads a block's code on a trigger |

Each of the four can also fetch the next route's code early, on a warning like the last section's:
Next.js and Nuxt when a link comes into view, SvelteKit when the pointer rests on one, which its template
asks for, and Angular once its router is given a preloading strategy. That is this section's reading of their documentation;
the next part was run.

## Telling Angular

Lesson 2's Angular project names its two components in `app.routes.ts`, so both are in the file every page
loads. The build says so:

```
ana@dev:~/meta/angular$ npm run build 2>&1 | sed -n '/Browser bundles/,/Server bundles/p' | grep -E '\.js |Initial total|Lazy chunk'
main-MEAHQ54B.js     | main             | 270.04 kB |                74.41 kB
                     | Initial total    | 270.04 kB |                74.41 kB
```

**One initial file, and no lazy ones.** Replace `src/app/app.routes.ts` with a version where each route
loads its component when it is first visited:

```typescript
// src/app/app.routes.ts: which component answers which address. Each is loaded when its
// address is first visited, so each is a chunk of its own.
import { Routes } from "@angular/router";

export const routes: Routes = [
  { path: "", loadComponent: () => import("./home").then((m) => m.Home), title: "Study planner" },
  { path: "courses/:slug", loadComponent: () => import("./course").then((m) => m.Course), title: "Study planner" },
];
```

The import of each component is gone from the top of the file, which matters: a static import anywhere
would put the component back in the initial file, whatever the route says.

```
ana@dev:~/meta/angular$ npm run build 2>&1 | sed -n '/Browser bundles/,/Server bundles/p' | grep -E '\.js |Initial total|Lazy chunk'
chunk-IBRQ2R5D.js    | -                | 267.53 kB |                73.83 kB
main-XHWRPD6J.js     | main             | 648 bytes |               648 bytes
                     | Initial total    | 268.17 kB |                74.48 kB
Lazy chunk files     | Names            |  Raw size | Estimated transfer size
chunk-74WP3QX3.js    | course           |   1.02 kB |                 1.02 kB
chunk-XJFROPDD.js    | home             | 903 bytes |               903 bytes
chunk-WYIPRWR6.js    | -                | 846 bytes |               846 bytes
```

**Lazy chunks for `home` and `course`, a third they share, and an initial total that barely moved.** The components were the
small part. What every page of an Angular application loads is the framework, and splitting your own
routes cannot make that smaller; it keeps it from growing with every page you add. The same is true, in
their own proportions, of the other three, and it is the number lesson 2 measured when it weighed the same
page in each.
