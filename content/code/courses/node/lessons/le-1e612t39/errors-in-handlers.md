---
title: An error in a handler
version: 1
---

**An exception in a request handler that nothing catches is an exception in the whole process.**
Lesson 1 and lesson 2 showed what that does to a program. In a server it means every request in
progress, from every user, dies with the one that threw.

```javascript
// fragile.js
import http from "node:http";

http
  .createServer((req, res) => {
    const { pathname } = new URL(req.url, "http://localhost");
    const code = decodeURIComponent(pathname.slice(1)); // throws on bad percent-encoding
    res.end(`you asked for ${code}\n`);
  })
  .listen(3000, "127.0.0.1", () => console.log("listening"));
```

One malformed path, from anybody:

```
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/ok; curl -s http://127.0.0.1:3000/%E0%A4%A; curl -s http://127.0.0.1:3000/ok; echo "curl exit code $?"
you asked for ok
curl exit code 7
```

and in the server's terminal:

```
ana@dev:~/server/native$ node fragile.js
listening
file:///home/ana/server/native/fragile.js:7
    const code = decodeURIComponent(pathname.slice(1)); // throws on bad percent-encoding
                 ^

URIError: URI malformed
    at decodeURIComponent (<anonymous>)
    at Server.<anonymous> (file:///home/ana/server/native/fragile.js:7:18)
    at Server.emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at HTTPParser.parserOnHeadersComplete (node:_http_common:122:17)

Node.js v22.22.0
```

**The second request killed the server**, and the third found nothing listening: curl's exit code 7
means it could not connect. The URL was the attacker's whole effort, and a service that falls over on
input like that has a bug, not bad luck. The same is true of an `async` handler whose promise
rejects: lesson 2's section on errors nobody caught showed that a rejection with no handler ends the
process too.

## Catching it at the edge

The fix is one `try` around the whole handler, so that every error becomes a response:

```javascript
// sturdy.js
import http from "node:http";

http
  .createServer(async (req, res) => {
    try {
      const { pathname } = new URL(req.url, "http://localhost");
      const code = decodeURIComponent(pathname.slice(1));
      res.end(`you asked for ${code}\n`);
    } catch (err) {
      console.error(`${req.method} ${req.url}: ${err.message}`);
      res.statusCode = err instanceof URIError ? 400 : 500;
      res.end(res.statusCode === 400 ? "bad request\n" : "internal error\n");
    }
  })
  .listen(3000, "127.0.0.1", () => console.log("listening"));
```

```
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/ok; curl -s http://127.0.0.1:3000/%E0%A4%A; curl -s http://127.0.0.1:3000/ok
you asked for ok
bad request
you asked for ok
```

Two rules are in that `catch`. **The details go to the log, and the client gets a short, fixed
sentence**: a stack trace in a response tells a stranger which files and libraries the server is
made of. And **the status says whose fault it was**: a 400 for a request that could never succeed,
a 500 for a failure of ours, which is the one that should wake somebody up. Lesson 6 shows the same
rule in Express, where one error-handling function does this for every route.
