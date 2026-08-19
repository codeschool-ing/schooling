---
title: Headers: the conversation's metadata
---

Request and response both carry **headers** — name and value pairs describing the content and the conditions, without being part of it.

On the request, the ones that show up most are `Host` (which site, since one server hosts several), `Accept` (which formats will do), `Authorization` (the credential) and `Cookie`. On the response, `Content-Type` (what this is), `Cache-Control` (how long to keep it) and `Set-Cookie`.

A wrong `Content-Type` is one of the most common causes of "it works on my server and not on the other one": the same file served as `text/plain` instead of `text/css` makes the browser refuse the stylesheet, and the page shows up with no styling at all and no visible error.
