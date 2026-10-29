---
title: The headers that decide it
version: 1
---

**`Cache-Control` says how long a copy is good and who may keep it**; `ETag` and `Last-Modified` give a
copy something to be checked with. Each is a response header from the server, and the checks are request
headers from the browser.

## Cache-Control

| directive | what it says |
|---|---|
| `max-age=N` | the copy is good for N seconds without asking |
| `s-maxage=N` | the same, for shared caches only; it overrides `max-age` there |
| `no-cache` | keep it, but ask every time before using it; despite the name, it is a rule about checking, not about storing |
| `no-store` | do not keep it anywhere |
| `public` | any cache may keep it, a shared one included |
| `private` | only the visitor's own browser may keep it |
| `immutable` | the file will never change at this address, so do not even check when the person reloads |
| `stale-while-revalidate=N` | for N seconds after it stops being fresh, a stale copy may be used while a fresh one is fetched |

## Checking a copy

**An `ETag` is a name for one version of a response**, chosen by the server, usually a hash of the body.
A browser that has a copy sends it back as `If-None-Match`, and a server whose current version has the
same ETag answers `304 Not Modified` with no body. `Last-Modified` and `If-Modified-Since` do the same
with a date, which is coarser, a second at best, and wrong for anything generated per request.

## Vary

**`Vary` names the request headers an answer depends on.** The planner already sends
`vary: accept-encoding` since lesson 6, because the same address answers with gzip to a browser that asks
for it and without to one that does not. A shared cache keeps one copy per value of the named headers;
without `Vary`, it could hand the compressed copy to a client that cannot read it.

## Age

**A shared cache adds `Age`**: how many seconds the copy it is sending has been in its store. It is how a
browser, or a person with `curl`, can tell a copy from a CDN from one fresh from the server, and the
section "A CDN of your own" reads it.
