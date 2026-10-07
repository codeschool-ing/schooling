---
title: Timeouts and cancelling
version: 2
---

**`fetch` has no timeout of its own.** A server that accepts the connection and never answers leaves
the promise pending for as long as the operating system lets the connection live. The way to give up
is a **signal**. This runs with `node`, so the server from the previous section has to be running in
its second terminal:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;

let t = performance.now();
try {
  await fetch("http://127.0.0.1:8080/api/slow?ms=3000", { signal: AbortSignal.timeout(1000) });
} catch (err) {
  console.log(`${err.name} after about ${round(performance.now() - t)} ms: ${err.message}`);
}

const controller = new AbortController();
t = performance.now();
setTimeout(() => controller.abort(), 300);
try {
  await fetch("http://127.0.0.1:8080/api/slow?ms=3000", { signal: controller.signal });
} catch (err) {
  console.log(`${err.name} after about ${round(performance.now() - t)} ms: ${err.message}`);
}
```

```
ana@dev:~/js$ node timeout.mjs
TimeoutError after about 1000 ms: The operation was aborted due to timeout
AbortError after about 300 ms: This operation was aborted
```

`/api/slow` waits three seconds before answering. Both requests gave up long before that:

- **`AbortSignal.timeout(1000)`** is a signal that fires by itself after 1000 ms. The request was
  abandoned at about 1000 ms with a `TimeoutError`;
- **an `AbortController`** is a signal you fire yourself, with `controller.abort()`. A timer fired it
  at 300 ms, and the request rejected with an `AbortError`. In a page, the same call goes in the
  handler of a Cancel button, or in the code that runs when the user leaves the screen that made the
  request.

The two errors have different names on purpose, so code can tell **"it took too long"** from **"we
stopped wanting it"**: the first is worth reporting to the user, the second usually is not.

Aborting stops the waiting on this side. **It cannot undo what the server already did**: a `POST` that
the server had already saved stays saved. That is one reason the next two sections treat sending data
and retrying it with care.

The next sections go back to `page`, which starts a server of its own on the same address. **Stop
the one in the second terminal first**, with Ctrl+C, or `page` stops with `EADDRINUSE` (lesson 1,
"When the setup fails").
