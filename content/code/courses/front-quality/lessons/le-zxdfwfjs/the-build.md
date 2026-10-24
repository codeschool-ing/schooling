---
title: The build, and what it is served with
version: 1
---

**The headers that matter most belong on the built site, the files a host will serve, so that is what
this lesson tests.** `npm run build` type-checks, then writes the production files to `dist/`:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 8 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                 0.41 kB │ gzip: 0.27 kB
dist/assets/index-DOOv8gtv.css  0.49 kB │ gzip: 0.33 kB
dist/assets/index-QOiF0uY7.js   3.22 kB │ gzip: 1.55 kB

✓ built in 95ms
```

**Three files and the data.** `index.html`, one JavaScript file and one stylesheet, each with a hash of its
contents in the name, so a browser can keep them for ever and a new build is new names. `public/` is copied
across as it is. And no inline script anywhere: Vite moved every line of the planner's code into
`assets/`, which is what makes a strict Content Security Policy possible.

`vite preview` serves `dist/` as a static host would, on port 4173, and it uses the same proxy for `/api`.
Here is what it answers with today:

```
ana@dev:~/planner$ curl -s -I http://localhost:4173/
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
Cache-Control: no-cache
Etag: W/"1a1-oQnFYEXs7j/YT1F2ilqAR+fppH0"
Date: Fri, 23 Oct 2026 23:28:46 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

**No security header at all**: the type of the content, a cache validator, the date. A browser reading
this page will run any script the page asks for, from anywhere, let any other site put the page in a
frame, and guess at content types. The next section writes the test that says what it should send.
