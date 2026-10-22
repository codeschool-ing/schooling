---
title: Conditional requests and caching headers
version: 1
---

**A client that already has a copy of a reply can ask "has it changed?" instead of asking for it
again**, and a server that can answer "no" with a 304 sends a status line and no body. Express makes
half of this automatic: `res.json` and `res.send` compute an `ETag`, a fingerprint of the body, and
answer 304 by themselves when the client sends that fingerprint back in `If-None-Match`.

With `server.js` running and one link in it:

```
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/links/vb3qxu | grep -i etag
ETag: W/"5e-KLu1io51n87g/2gy6Oj3o56wm4s"
ana@dev:~/server/links$ curl -si -H 'If-None-Match: W/"5e-KLu1io51n87g/2gy6Oj3o56wm4s"' http://127.0.0.1:3000/links/vb3qxu | head -1
HTTP/1.1 304 Not Modified
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/vb3qxu
302
ana@dev:~/server/links$ curl -si -H 'If-None-Match: W/"5e-KLu1io51n87g/2gy6Oj3o56wm4s"' http://127.0.0.1:3000/links/vb3qxu | grep -iE '^HTTP|^etag'
HTTP/1.1 200 OK
ETag: W/"5e-GCroJt7mlVyGKv5hLdbPiIy8v04"
```

**The second request sent the fingerprint and got 304 with no body**: the link had not changed. The
fourth came after the third, a visit, which changes `visits`, so the fingerprint no longer matched and the whole
link came back with a new one. The `W/` in front means a *weak* ETag: two bodies with the same meaning
may share one, which is all a JSON API needs.

The ETag is computed from the body after the route has built it, so a 304 saves the network and not
the work. A route that is expensive to compute needs a cache in front of it, which `servers-cache`
builds.

## Saying how long a copy may be kept

`ETag` answers "has it changed?". **`Cache-Control` answers "may you keep it at all, and for how
long?"**, and the server sets it per route:

| `Cache-Control` | means |
|---|---|
| `no-store` | do not keep a copy anywhere: the admin's list, anything personal |
| `no-cache` | keep it, and ask with `If-None-Match` before every use |
| `max-age=3600` | use the copy for an hour without asking |
| `private` | a browser may keep it; a shared proxy may not |

The admin's list says `no-store` since the section on validation, and a request shows it:

```
ana@dev:~/server/links$ curl -si -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links | grep -iE '^(cache-control|etag)'
cache-control: no-store
ETag: W/"60-t+j0ML9EqfCyDHsGPRTgvFk0j+I"
```

A short link's redirect says nothing about caching, so a browser treats it by its defaults, which for a
302 is to ask every time; the section on response helpers chose 302 for exactly that.
