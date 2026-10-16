---
title: A hundred connections and no extra threads
version: 1
---

**A socket is not read on the pool.** The operating system can watch thousands of sockets at once
and say which ones have data, through `epoll` on Linux, `kqueue` on macOS and I/O completion ports
on Windows. libuv hands every socket to that mechanism and asks one question in the poll phase:
*which of these is ready?* No thread waits on any of them.

This program counts its own threads while it does it. It starts a server that answers every request
after one second, sends it a hundred requests at once with `fetch`, and then reads one file:

```javascript
// threads.js: how many threads this process has, before and after.
const fs = require("node:fs");
const http = require("node:http");

const threads = () => fs.readFileSync("/proc/self/status", "utf8").match(/^Threads:\s+(\d+)/m)[1];
console.log(`at start: ${threads()} threads`);

// A server that answers every request one second later, and 100 requests to it at once.
const server = http.createServer((req, res) => setTimeout(() => res.end("ok"), 1000));
server.listen(3001, "127.0.0.1", async () => {
  const start = performance.now();
  const replies = await Promise.all(
    Array.from({ length: 100 }, () => fetch("http://127.0.0.1:3001/").then((r) => r.text())),
  );
  console.log(`${replies.length} replies in ${Math.round(performance.now() - start)} ms, ${threads()} threads`);
  fs.readFile(__filename, () => {
    console.log(`after one fs.readFile: ${threads()} threads`);
    server.close();
  });
});
```

`/proc/self/status` is a file Linux keeps for every process, and its `Threads:` line is the count.

```
ana@dev:~/server/loop$ node threads.js
at start: 7 threads
100 replies in 1161 ms, 7 threads
after one fs.readFile: 11 threads
```

Read the three lines in order:

1. **The process starts with several threads already.** Besides the main one, V8 keeps a few of its
   own, for compiling and for collecting garbage in the background.
2. **A hundred requests, each waiting a second, took a little over one second, and added no
   threads.** Both ends of all hundred connections were in the same process, watched by `epoll`.
   A thread per request would have meant a hundred more, or a queue in front of a few.
3. **The first `fs.readFile` started the pool**, and the count went up by four. libuv creates the
   pool the first time something needs it.

That is the whole case for Node on a server in one transcript: the expensive resource, a thread, is
not spent on waiting. The address is `127.0.0.1` rather than a name because a name would go
through `dns.lookup`, and that is on the pool.
