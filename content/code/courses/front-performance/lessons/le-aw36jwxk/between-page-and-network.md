---
title: Between the page and the network
version: 1
---

**A service worker is a script the browser runs apart from the page, that sees every request the page
makes and can answer it itself.** It has no window and no DOM. It is installed by a page, keeps running
between visits as the browser sees fit, and from then on every request from the pages it controls goes
to it first: it can answer from a cache of its own, ask the network, or both.

## What makes it different from lesson 9's caches

| | the HTTP cache | a service worker |
|---|---|---|
| who decides | the server, through headers | your script, request by request |
| what it keeps | whatever the headers allow | whatever the script puts in its **Cache Storage** |
| without the network | nothing that needs a check works | anything it kept can be answered |
| when it changes | when the headers say | when a new version of the script is installed |

**Cache Storage is a store of request and response pairs**, under names the script chooses, which only
the script, or the page, reads and writes. The browser never expires it on its own schedule, though it can
clear a site's storage when the disk is short, as it can any site data.

## Its life

1. **register**: a page calls `navigator.serviceWorker.register("/sw.js")`. The browser downloads the
   file.
2. **install**: the script's `install` event runs once, the moment to fetch what it wants to have from the
   start.
3. **activate**: once nothing older is controlling pages, `activate` runs, the moment to delete what an
   older version left.
4. **fetch**: from then on, every request from a controlled page is a `fetch` event, and the script decides
   the answer.

Two rules come with the power. **A service worker only runs on HTTPS, or on `localhost`**, because a script
that answers every request is exactly what an attacker on the network would want to install. And **its
scope is its folder**: a worker served from `/sw.js` controls the whole site, one from `/assets/sw.js` only
the addresses under `/assets/`. That is why the planner's goes in `public/`, which Vite copies to the root,
unhashed, under a name that never changes.
