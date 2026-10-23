---
title: What streaming gives up
version: 1
---

**A response begins with its status and headers, so streaming commits to them before the page is
finished.** That is the price of sending early, and lesson 2 already paid it once without knowing:
Next.js called `notFound()` on a partly prerendered page, and answered 200, because the 200 had left
with the shell.

`curl -i` prints the headers before the body, and the `sed` stops at the blank line that ends them:

```
ana@dev:~/planner$ curl -si http://localhost:3005/courses/git | sed '/^\r$/q'
```

There is no `Content-Length`, because the server did not know the length when it started.
**`Transfer-Encoding: chunked` is HTTP/1.1's way of sending a body in pieces**, each with its own
length in front. HTTP/2 and HTTP/3 have frames for the same thing and no header for it.

## Four things to decide before the first byte

1. **The status.** `stream.ts` looks the course up before writing anything, so an unknown course is a
   404. Anything that can make a page not exist, or require a sign-in, or move, has to be known before
   streaming starts, or the answer is a 200 with an error drawn inside it.
2. **The headers.** A cookie, a redirect, a cache header that depends on what the slow part finds:
   none can be added once the body has started.
3. **What a failure looks like.** If the slow query fails after the shell has gone, the server can
   only send an error in the body, inside the placeholder, and close the response. The page should
   say something useful in that place, and the monitoring should know the request failed although its
   status says 200.
4. **What sits between the server and the browser.** A proxy, a CDN or a compression layer that
   **buffers** the response holds every piece until the end, and then sends them all at once: the page
   arrives as if it had never streamed, and nothing reports it. Nginx, for instance, buffers responses
   from the server behind it unless that is switched off, which is why servers that stream often send
   a header such as `X-Accel-Buffering: no`. The only way to know is to measure through the real path,
   with `chunks.ts` or the browser, rather than against `localhost`.

## When it is worth it

Streaming pays when a page has a slow part and a quick part, and the quick part is useful on its own:
a heading, the navigation, the first screen of a product page whose reviews come later. It does not
pay when the slow part is the page, a search result for example, where a placeholder only delays the
moment the person learns there is nothing to see yet. Lesson 5 gives that difference a number: the
quick part is what decides how soon the page seems to load.
