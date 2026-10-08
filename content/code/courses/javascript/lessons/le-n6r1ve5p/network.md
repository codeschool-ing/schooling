---
title: The network tab
version: 2
---

**The Network panel lists every request a page makes: what it asked for, the status that came
back, the size and the timing.** When a page shows the wrong data, or none, this is where you find
out whether the problem is in the page or in the server. `page --network` prints one line per
response. `missing.html` loads this script with `<script type="module">`, because it uses `await`
at the top level, as lesson 9 explained:

```javascript
for (const path of ["/api/books/2", "/api/books/9", "/api/broken"]) {
  const res = await fetch(path);
  console.log(path, "answered", res.status);
}
```

```
ana@dev:~/js$ page missing.html --network
net  GET /missing.html  200  document  165 B
/api/books/2 answered 200
net  GET /missing.js  200  script  150 B
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
/api/books/9 answered 404
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
/api/broken answered 500
net  GET /api/books/2  200  fetch  87 B
net  GET /api/books/9  404  fetch  21 B
net  GET /api/broken  500  fetch  41 B
```

Each `net` line has the method, the address, the **status**, the **type** of request and the size of
the body. `page` prints a line once the body has arrived, so the lines for the three requests come
after the page's own messages.

Two things here are worth knowing before they confuse you:

- **Chromium logged an `[error]` for the 404 and the 500 by itself**, `Failed to load resource`,
  although the page's code handled both. That message comes from the browser's network layer, not
  from your code;
- **`fetch` did not throw.** A 404 and a 500 are answers, as lesson 16 showed, and the code read
  their status. In the panel they are drawn in red, which says "the server said no", not "the code
  crashed".

In DevTools, clicking a request shows its headers, the body sent and the body received. The
**Preserve log** option keeps the list across a reload or a redirect, and **Disable cache**
makes every request go to the server. Neither is captured here.

## The waterfall

The time column of the Network panel draws each request as a bar on a shared time line: the
**waterfall**. It is the fastest way to see requests that wait for each other when they did not
need to. `waits.html` loads this one as a module too:

```javascript
const get = (book) => fetch(`/api/slow?ms=400&book=${book}`).then((res) => res.json());
const tenths = (ms) => Math.round(ms / 100) * 100;

async function oneByOne() {
  const t0 = performance.now();
  await get(1);
  await get(2);
  await get(3);
  console.log(`one by one: about ${tenths(performance.now() - t0)} ms`);
}

async function together() {
  const t0 = performance.now();
  await Promise.all([get(1), get(2), get(3)]);
  console.log(`together: about ${tenths(performance.now() - t0)} ms`);
}

await oneByOne();
await together();
```

```
ana@dev:~/js$ page waits.html --wait 3000 --waterfall
one by one: about 1200 ms
together: about 400 ms
start  took    request
    0     0  GET /waits.html              #
    0     0  GET /waits.js                #
    0   400  GET /api/slow?ms=400&book=1  ####
  400   400  GET /api/slow?ms=400&book=2      ####
  800   400  GET /api/slow?ms=400&book=3          ####
 1200   400  GET /api/slow?ms=400&book=1              ####
 1200   400  GET /api/slow?ms=400&book=2              ####
 1200   400  GET /api/slow?ms=400&book=3              ####
```

`--waterfall`, from `devtools.mjs`, draws the same time line in text, rounded to 100 ms, with one `#` per 100
ms. The first three requests form a staircase. Each starts when the previous one ends, because
each `await` waits before the next `fetch` is sent. The last three start together, because
`Promise.all` sent all three before waiting for any.

**A staircase in the waterfall is the shape of a sequential `await`.** When the requests do not
depend on each other, sending them together turns three waits into one, as lesson 14 showed.
`front-performance`, lesson 6, takes the waterfall further, with the Performance panel and
Lighthouse.
