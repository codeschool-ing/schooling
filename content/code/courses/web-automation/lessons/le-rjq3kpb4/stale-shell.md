---
title: The copy that outlives a deploy
version: 1
---

A cache-first worker answers the shell from its own copy, and nothing in quitanda's worker ever
replaces that copy. **So after a deploy, a visitor who has been before keeps running the old
shell**, and keeps running it until something changes the worker itself. Lesson 4 met a cache the
server steers with headers. This one is steered by a script, and the headers do not reach it.

That is the belief to drop: *the server sends `Cache-Control: no-cache`, so the browser always
checks.* Lesson 1 set that header on every file the shop serves, and it governs the browser's
**HTTP cache**. A service worker keeps its copies in a different store, the **Cache Storage**, and
answers from it before the HTTP cache is ever consulted. `caches.match` in `sw.js` reads no header
and checks with nobody.

## A deploy, played by hand

Open `app/public/spa/spa.js` in your editor and change the heading of the fruit view from `Fruit` to
`Fresh fruit`, as a developer's next release might. Start the shop, and the server has the new file:

```
%%CAP stale-curl%%
```

Now start the shop with its log on, and run `spa-look.mjs` a third time, still with the profile of
the earlier runs:

```
%%CAP stale%%
```

And the server's side of it:

```
%%CAP stale-log%%
```

%%PROSE stale%%

Change the heading back to `Fruit` before going on, so the next lessons find the file as they
expect it.

## What it means for a suite

**A test suite never sees this by default.** Every Playwright test starts in a new browser context,
with no worker and no copies, so every test is a first visit, and a first visit always gets the new
build. The defect lives entirely in the returning visitor, which is the one your users are.

Catching it takes two versions of the app and a browser that has met the first: open the site on
the old build, deploy the new one, open it again in the same profile, and check what is on the
screen. `spa-look.mjs` just did that by hand. In a team it belongs where two builds meet, a staging
environment that a release goes through; `manual-testing` lesson 21 is about environments and
`testing-cicd` lesson 5 about the pipeline that would run it.

The remedy is the developer's, and it depends on what the app promises. The usual ones are a worker
that asks the network first for the page and falls back to its copy only offline, or a worker that
names its cache by version and deletes the old copies when a new version takes over, often with a
banner that says *a new version is available*. Whichever it is, the tester's question is the same
one this section asked: **after a deploy, what does somebody who was here yesterday see?**

## Seeing it in the browser

In Chrome's developer tools, the **Network** panel marks a response that came from a worker as
`(ServiceWorker)` in its **Size** column, so the reload of a stale page looks different there from
a fresh one. The **Application** panel lists the installed workers, with a button to unregister one,
and its **Cache storage** entry shows what each cache holds: `shell-v1`, with its three files. When
somebody reports that they still see yesterday's page, those two places tell you whether lesson 4's
cache or this one is the answer.
