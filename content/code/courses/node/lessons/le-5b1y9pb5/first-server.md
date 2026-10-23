---
title: A first server
version: 1
---

**A web server is a program that waits for a request and writes a reply.** Node has one in its
standard library, so the first one needs nothing installed. Make a folder for it and save this as
`~/server/hello/hello.mjs`:

```javascript
// hello.mjs
import http from "node:http";

const server = http.createServer((request, response) => {
  console.log(request.method, request.url);
  response.end(`hello from Node ${process.version}, you asked for ${request.url}\n`);
});

server.listen(3000, "127.0.0.1", () => {
  console.log("listening on http://127.0.0.1:3000");
});
```

You do not need to follow every line yet; lesson 5 takes this apart. In outline, `createServer`
is given a function that Node calls once **for every request**, with the request and the response
as its two arguments. `listen` opens port 3000 on `127.0.0.1` and calls its own function once the
port is open. The file ends in `.mjs` because it uses `import`; lesson 3 is about why that ending
matters.

## Two terminals

A server does not finish. It sits there waiting, so it needs a terminal of its own. In the first
one, go to the folder and start it:

```
ana@dev:~/server/hello$ node hello.mjs
listening on http://127.0.0.1:3000
```

The terminal is now taken; the prompt does not come back. Open a second terminal and ask the server
for something:

```
ana@dev:~/server/hello$ curl -s http://127.0.0.1:3000/
hello from Node v22.22.0, you asked for /
ana@dev:~/server/hello$ curl -si http://127.0.0.1:3000/anything
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:19:57 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Content-Length: 50

hello from Node v22.22.0, you asked for /anything
```

`curl` sent a request and printed the reply's body; `-s`, for silent, stops it drawing a progress
meter when its output is not a screen. With `-i` it prints the reply's status line and headers too,
and **Node wrote all of those headers itself**: the date, the length of the body, and
two that say the connection may stay open for the next request. Lesson 5 says what each is for.

Back in the first terminal, the server printed a line per request, and **Ctrl-C** stopped it:

```
ana@dev:~/server/hello$ node hello.mjs
listening on http://127.0.0.1:3000
GET /
GET /anything
^C
```

## Only one program per port

A port belongs to one program at a time. Start the server while another copy is still running, and
the second one fails before it serves anything:

```
ana@dev:~/server/hello$ node hello.mjs
node:events:497
      throw er; // Unhandled 'error' event
      ^

Error: listen EADDRINUSE: address already in use 127.0.0.1:3000
    at Server.setupListenHandle [as _listen2] (node:net:1940:16)
    at listenInCluster (node:net:1997:12)
    at node:net:2206:7
    at process.processTicksAndRejections (node:internal/process/task_queues:90:21)
Emitted 'error' event on Server instance at:
    at emitErrorNT (node:net:1976:8)
    at process.processTicksAndRejections (node:internal/process/task_queues:90:21) {
  code: 'EADDRINUSE',
  errno: -98,
  syscall: 'listen',
  address: '127.0.0.1',
  port: 3000
}

Node.js v22.22.0
```

**`EADDRINUSE`, address in use, is the error you will meet most in this course.** It almost
always means an earlier copy of the server is still running in another terminal. Find that terminal
and press Ctrl-C there. The rest of the message is a stack trace, which is the section after next.
