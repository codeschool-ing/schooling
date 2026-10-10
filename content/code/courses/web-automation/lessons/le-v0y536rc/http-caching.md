---
title: What the browser keeps, and for how long
version: 1
---

A browser keeps a copy of much of what it is sent, in its **HTTP cache**, and the next time a page
asks for the same address it has three choices: use the copy without asking anybody, ask the server
whether the copy is still good, or fetch the thing again. **The server decides which**, with
headers on each response, and the browser obeys them.

The usual first picture is that the cache is a speed-up with no effect on what you see: the page
loads faster and is otherwise the same. That picture is wrong in the one case a tester cares about.
When the copy is used without asking, **the server is not consulted at all**, so a change made on
the server since then is invisible to that browser, however correct the server is now.

## Four headers, and one status

| on the response | what the browser may do with its copy |
|---|---|
| `Cache-Control: max-age=600` | use it for 600 seconds **without asking**; after that, ask |
| `Cache-Control: no-cache` | keep it, but **ask the server before every use** |
| `Cache-Control: no-store` | keep nothing; fetch it again every time |
| `ETag: "…"` | a fingerprint of the content, to quote back when asking |

**`no-cache` is the badly named one.** It does not mean *do not cache*; that is `no-store`. It means
*cache, and check first*. The check is a request carrying the fingerprint in an `If-None-Match`
header, and the server has two answers: `304 Not Modified`, with no body, which tells the browser
its copy is still right; or `200` with the new content and a new fingerprint.

## The shop's own files

Lesson 1 built the server so that every file in `app/public/` carries `no-cache` and an `ETag`.
`curl` keeps no cache of its own, so it shows exactly what the server says. Here `-D -` prints the
response headers and `-o /dev/null` throws the body away, with the shop running:

```
%%CAP static-200%%
```

Ask again quoting that fingerprint, as a browser holding a copy would:

```
%%CAP static-304%%
```

**A `304` and no body**: the stylesheet was not sent a second time. A browser that gets this answer
draws the page from its copy, and the cost was one short round trip. With `max-age` the cost would
be no round trip at all, which is why sites use long `max-age` values for files whose names change
when their content does, like `app.3f9c1a.js`. A new version then has a new address, and the old
copy is never asked for again. The shop's files keep their names, so they are checked every time.

## Where else a copy can live

The browser is not the only place that keeps responses. A **CDN** or a proxy between the browser
and the server can keep one too, for every visitor at once, and `max-age` applies to it unless the
response also says `private`. That cache is outside the browser, so nothing in this lesson clears
it. A page can also run a **service worker**, a script that sits between the page and the network
and keeps its own copies; lesson 5 is about that one.

What follows stays with the browser's own cache, because that is the one every test runs inside.
