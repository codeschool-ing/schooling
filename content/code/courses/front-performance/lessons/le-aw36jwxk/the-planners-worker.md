---
title: The planner's worker
version: 1
---

**The planner's service worker is one file, `public/sw.js`**, plain JavaScript, because Vite copies the
files in `public/` as they are and the browser fetches this one by its address. The next section explains
its three strategies one by one; here it is whole, to save and to read:

```schooling-example
{"language": "javascript", "file": "public/sw.js", "parts": [
 {"code": "// public/sw.js: the planner's service worker. It sits between the planner's pages and\n// the network, and answers from a cache of its own when the network is slow or gone.\nconst CACHE = \"planner-v1\";", "note": "One cache, named with a version. A new version of this file names a new cache, which is how the old copies are let go."},
 {"code": "self.addEventListener(\"install\", (event) => {\n  event.waitUntil(caches.open(CACHE).then((cache) => cache.add(\"/offline.html\")));\n});", "note": "install runs once per version. waitUntil keeps the worker installing until the promise settles, and a failure here means it is not installed at all."},
 {"code": "self.addEventListener(\"activate\", (event) => {\n  event.waitUntil(caches.keys().then((names) =>\n    Promise.all(names.filter((name) => name !== CACHE).map((name) => caches.delete(name)))));\n});", "note": "activate runs when this version takes over: every cache with another name is an older version's."},
 {"code": "self.addEventListener(\"fetch\", (event) => {\n  const { request } = event;\n  if (request.method !== \"GET\" || new URL(request.url).origin !== location.origin) return;\n  if (new URL(request.url).pathname.startsWith(\"/assets/\")) event.respondWith(cacheFirst(request));\n  else if (request.mode === \"navigate\") event.respondWith(networkFirst(request));\n  else event.respondWith(staleWhileRevalidate(event, request));\n});", "note": "Every request from a controlled page arrives here. A handler that does not call respondWith leaves the request to the browser, as if the worker were not there: the beacon to /vitals and anything for another server go that way."},
 {"code": "async function cacheFirst(request) {\n  const cache = await caches.open(CACHE);\n  return (await cache.match(request)) ?? fetchAndKeep(cache, request);\n}", "note": "Hashed files: the copy if there is one, which is always right."},
 {"code": "async function networkFirst(request) {\n  const cache = await caches.open(CACHE);\n  try {\n    return await fetchAndKeep(cache, request);\n  } catch {\n    return (await cache.match(request)) ?? (await cache.match(\"/offline.html\"));\n  }\n}", "note": "Pages: the network first, so a visitor online sees the newest page; the last copy when it fails; the offline page when there is no copy."},
 {"code": "async function staleWhileRevalidate(event, request) {\n  const cache = await caches.open(CACHE);\n  const kept = await cache.match(request);\n  const fresh = fetchAndKeep(cache, request);\n  event.waitUntil(fresh.catch(() => {}));\n  return kept ?? fresh;\n}", "note": "Everything else: the copy at once, and a fresh one fetched for next time. Offline the fresh one fails, which is the case this exists for, so that failure is let go on purpose; with no copy to answer, the same failure reaches the page instead."},
 {"code": "async function fetchAndKeep(cache, request) {\n  const response = await fetch(request);\n  if (response.ok) await cache.put(request, response.clone());\n  return response;\n}", "note": "A response can be read once, so the cache gets a clone. Only a successful one is kept: an error page kept would be served as if it were the page."}
]}
```

## The offline page

`install` fetches one file before anything else: the page to show at an address the worker has no copy of.
Save it as `public/offline.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Offline · Study planner</title>
  </head>
  <body style="font: 16px/1.5 system-ui, sans-serif; max-width: 40rem; margin: 0 auto; padding: 1rem">
    <h1>You are offline</h1>
    <p>This page has not been opened on this device yet, so there is no copy of it here.
      The pages you have opened before still work. <a href="/">All courses</a></p>
  </body>
</html>
```

Its style is inline, because it has to work with nothing else in the cache.

## Registering it

At the end of `src/main.ts`:

```typescript

// The service worker, registered once the page has loaded, so that its first download
// does not compete with the page's own.
const register = () => navigator.serviceWorker.register("/sw.js");
if ("serviceWorker" in navigator) {
  if (document.readyState === "complete") register();
  else addEventListener("load", register);
}
```

`load` is the moment the page has finished with its own requests, so the worker's download, and the
requests it makes while installing, do not compete with them.

## One thing server.ts never needed

**`server.ts` has never served an `.html` file**, so its table of types has no entry for one, and it would
send the offline page as `application/octet-stream`: a file to download, not a page. The table also lacks
the types of lesson 7's pictures and fonts, which have gone out as octet-streams since, and worked because
browsers look inside a file they were told nothing about. Replace the table with one that says what each
file is:

```typescript
const types: Record<string, string> = {
  ".js": "text/javascript", ".css": "text/css", ".json": "application/json", ".svg": "image/svg+xml",
  ".html": "text/html; charset=utf-8", ".avif": "image/avif", ".webp": "image/webp", ".jpg": "image/jpeg",
  ".png": "image/png", ".woff2": "font/woff2",
};
```

Build, restart `server.ts`. The next sections take the browser off the network to see what the worker does.
