---
title: The best CORS is none
version: 1
---

**The planner never needed any of this, because its page has been asking its own origin since lesson
5.** Vite's proxy sends `/api` from `http://localhost:5173` on to port 3000 behind the browser's back, so
the browser sees one origin and applies no CORS rules at all. The same holds when the app is published,
if the API is served under the site's own address, `https://planner.example/api/…`, by the same server
or a reverse proxy in front of both.

That arrangement has three advantages, and they are why it is the first choice:

- **No preflight**, so no extra round trip before every `POST`.
- **Cookies are same-site** without any `SameSite=None`, and the lesson 6 cookie works as it is.
- **Nothing to get wrong**: no allowlist to keep in step with the places the app is published, and no
  wildcard to be tempted by.

## When CORS is the answer

Some APIs are meant to be called from other origins: a public API other people's sites use, or one API
behind several apps on different domains. Then the allowlist of the last section is the tool, written from the list of sites that are meant to use
it. Test it in both directions, as the planner's is: the origin that should be allowed is, and one that
should not be is not.

## What CORS is not

It is worth saying once more, because the error makes it look otherwise: **CORS is the server giving the
browser permission to relax a rule; it is not a lock on the server.** A request blocked by CORS reached
the server; `curl` reads the response; a script on another site can still make the person's browser
*send* a request with their cookies, though it cannot read the answer. That last case is cross-site
request forgery, and lesson 9 closes it with `SameSite` and a check of the `Origin` header on every
request that changes something.
