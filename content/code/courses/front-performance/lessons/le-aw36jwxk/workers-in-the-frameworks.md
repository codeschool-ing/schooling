---
title: Workers in the frameworks
version: 1
---

**Writing a worker by hand, as this lesson did, is how to understand one; writing every route of a large
application by hand is how to get one wrong.** The list of hashed files a worker should keep changes with every
build, and a tool that reads the build can write it. **Workbox**, Google's library, is that tool for most
projects, and the frameworks reach it, or their own, by different roads. This section was read from each
project's documentation and package; none of it was run.

| | the usual way | what it writes |
|---|---|---|
| **Next.js** | its documentation's guide writes `public/sw.js` by hand, for notifications; for offline caching, the Serwist package, `@serwist/next`, built on Workbox's ideas | a worker with the build's files listed |
| **Nuxt** | the module `@vite-pwa/nuxt` | through `vite-plugin-pwa`, a Workbox worker and the manifest of lesson 11 |
| **SvelteKit** | built in: a file `src/service-worker.js` is bundled and registered on its own, and the module `$service-worker` gives it the list of the build's files and a version string | your worker, with the lists it needs written for it |
| **Angular** | `ng add @angular/pwa`, which installs `@angular/service-worker` | Angular's own worker, configured in `ngsw-config.json`: groups of assets fetched at install or on use, and groups of data with a *performance* or *freshness* strategy |

**What none of them can decide is the strategy.** Each gives you cache first, network first and
stale while revalidate under some name, and each leaves the choice of which files get which to the project,
because it depends on how often each changes and how stale it may be, which is what this lesson's three sections
of strategy were about. SvelteKit's is the closest to this lesson: it gives the list and leaves the code to you.
