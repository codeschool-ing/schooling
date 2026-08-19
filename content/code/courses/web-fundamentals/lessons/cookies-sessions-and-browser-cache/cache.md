---
title: Cache: not asking again for what has not changed
---

The fastest way to load a file is not to load it. The **cache** keeps the response and reuses it while it is still valid, and the server is what decides that, through `Cache-Control`.

`max-age=3600` says "good for an hour, do not even ask". `no-cache` says "you may keep it, but confirm before using it" — the browser sends a conditional request and gets `304 Not Modified` if nothing changed, which saves the whole body. `no-store` says "do not keep it", and it is the right call for a bank statement page.

The practical tension is between caching a lot (fast, but the user sees the stale version) and caching little (always current, but slow). The standard way out is the **fingerprinted name**: `app.9f2c1a.css` can be cached for a year, because any change changes the file name and the HTML starts pointing at a different one.
