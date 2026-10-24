---
title: The error, seen in a real browser
version: 1
---

**The browser reports a CORS failure in its console and hands the page nothing but a `TypeError`**,
which is why the error confuses people the first time: the page's code learns only that the fetch
failed, and the reason is somewhere else. A short program shows both halves at once. It opens a page in
Chromium, runs one expression in it, and prints the requests the page made to other origins, what the
console said, and the result. Save it as `server/look.mjs`:

```javascript
// server/look.mjs
import { chromium } from "@playwright/test";

const [address, code] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const origin = new URL(address).origin;
page.on("request", (request) => {
  if (new URL(request.url()).origin !== origin) console.log(`request:  ${request.method()} ${request.url()}`);
});
page.on("console", (message) => {
  if (!message.text().startsWith("[vite]")) console.log(`console:  ${message.text()}`);
});
await page.goto(address);
console.log("result:  ", await page.evaluate(code));
await browser.close();
```

It skips the console lines Vite's own client prints, which say only that it connected. With the API and
the dev server running, here is the planner's page asking the API directly, on its own port, rather
than through the proxy:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ 'fetch("http://localhost:3000/api/plan").then((r) => r.status, (e) => String(e))'
request:  GET http://localhost:3000/api/plan
console:  Access to fetch at 'http://localhost:3000/api/plan' from origin 'http://localhost:5173' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
console:  Failed to load resource: net::ERR_FAILED
result:   TypeError: Failed to fetch
```

**Four lines, and each says something different.** The browser *did* send the request: it is in the
list. The console says why the page may not read the answer, `No 'Access-Control-Allow-Origin' header`,
naming both origins. And the page got `TypeError: Failed to fetch`, with no status, no body and no
reason.

## The request arrived

That first line is the part to remember. **CORS did not stop the request from reaching the server**; it
stopped the page from reading the response. The server got a GET, found no cookie, and answered 401, the
same answer `curl` gets, which has no same-origin policy at all:

```
ana@dev:~/planner$ curl -s -i http://localhost:3000/api/plan
HTTP/1.1 401 Unauthorized
content-type: application/json
Date: Fri, 23 Oct 2026 23:20:57 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"error":"sign in first"}
```

So CORS is no protection for the server. Anything that is not a browser ignores it, and a request with
side effects, a payment or a deletion, can happen even when the page that sent it cannot read what came
back. Protecting a server from requests it should not act on is lesson 9's subject, and CORS is not part
of the answer.
