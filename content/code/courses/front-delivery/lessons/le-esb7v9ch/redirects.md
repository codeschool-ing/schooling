---
title: Redirects, and which code to use
version: 1
---

**A redirect is a response with a status in the 300s and a `Location` header, and the status tells the
browser, and every search engine and cache, how long to believe it.** Choosing the code is choosing that
duration and what happens to the request's method, and the four in use have exact meanings:

| code | name | means | method on the way |
|---|---|---|---|
| 301 | Moved Permanently | this address is gone for good; use the new one from now on | may turn a `POST` into a `GET` |
| 302 | Found | go there this time; ask me again next time | may turn a `POST` into a `GET` |
| 307 | Temporary Redirect | like 302 | kept exactly |
| 308 | Permanent Redirect | like 301 | kept exactly |

**A permanent redirect is remembered.** Browsers cache a 301 or 308 without being told to, so a
permanent redirect sent by mistake keeps sending people to the wrong place after you have removed it,
until each visitor clears their cache. Use 302 while you are unsure and 301 when the decision is made.
For a static site of pages, the method question rarely arises, and 301 is what the rules files default
to; Cloudflare Pages is the exception, and defaults to 302, so write the code in every rule.

## A renamed address

The planner's course pages once lived at `/courses/<id>`, plural, and links to them are still out there.
One rule sends every old address to its new one, keeping the part that names the course. The file goes
in `public/`, so Vite copies it into `dist/`, where Netlify, Cloudflare Pages and now `host.mjs` look for
it:

```
# public/_redirects
/courses/* /course/:splat 301
```

Build, start the host in another terminal with `node host.mjs`, as in lesson 1, and ask for an old
address:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ curl -sI http://127.0.0.1:8080/courses/git
HTTP/1.1 301 Moved Permanently
location: /course/git
Date: Fri, 23 Oct 2026 23:04:20 GMT
Connection: keep-alive
Keep-Alive: timeout=5

ana@dev:~/planner$ curl -sL -o /dev/null -w '%{http_code} %{url_effective}\n' http://127.0.0.1:8080/courses/git
404 http://127.0.0.1:8080/course/git
```

The response carries no page, only the status and where to go: `/course/git`, with `git` taken from
what the `*` matched. A browser follows it without the reader noticing, and the address bar shows the new
one. `curl -L` follows it too, and lands on `/course/git`, which is still a 404 on this host: that
address is the next section's problem.

## What a redirect cannot fix

A redirect sends the browser to another address, so it changes what the address bar says. That is right
for a moved page and wrong for the next section's problem: an address that is correct, that the app
knows how to draw, and that the host has no file for. Sending `/course/git` to `/` would break every
deep link the app makes. That needs a rewrite, which serves a different file **at the same address**.
