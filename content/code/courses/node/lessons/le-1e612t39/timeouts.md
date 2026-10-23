---
title: Timeouts, and the client that never finishes
version: 1
---

**A connection that sends nothing still costs a server something**: a socket, a little memory, a
place in the list `epoll` watches. A client that opens hundreds of connections and sends each request
one byte at a time, never finishing, can hold a server's capacity without ever completing a request.
Node's defence is three timeouts on the server object:

```
ana@dev:~/server/native$ node -p 'const s = require("node:http").createServer(); [s.headersTimeout, s.requestTimeout, s.keepAliveTimeout]'
[ 60000, 300000, 5000 ]
```

| setting | default | what it limits |
|---|---|---|
| `headersTimeout` | 60 000 ms | how long a client may take to send the request line and headers |
| `requestTimeout` | 300 000 ms | how long it may take to send the whole request, body included |
| `keepAliveTimeout` | 5 000 ms | how long an idle connection stays open, waiting for a next request |

The third is the `Keep-Alive: timeout=5` that lesson 1's first server sent: Node tells the client how
long it will keep the connection after a reply.

## Watching one fire

To see a timeout without waiting a minute, a server with `headersTimeout` set to two seconds, and a
client that sends half a request line and then nothing:

```javascript
// slow.js
import http from "node:http";
import net from "node:net";

const server = http.createServer({ connectionsCheckingInterval: 500 }, (req, res) => res.end("hello\n"));
server.headersTimeout = 2000;
server.requestTimeout = 2000;

server.listen(3000, "127.0.0.1", () => {
  const start = Date.now();
  const socket = net.connect(3000, "127.0.0.1", () => socket.write("GET / HTTP/1.1\r\nHost: loc"));
  socket.on("data", (d) => console.log(`after ${Date.now() - start} ms the server sent:\n${d}`));
  socket.on("close", () => server.close());
});
```

`node:net` is the TCP layer under `node:http`, and here it plays a client that writes bytes by hand.

```
ana@dev:~/server/native$ node slow.js
after 2504 ms the server sent:
HTTP/1.1 408 Request Timeout
Connection: close
```

**The server waited, then answered `408 Request Timeout` and closed the connection.** Node does not
watch each connection to the millisecond: it checks all of them on a timer of its own, every
`connectionsCheckingInterval`, which is 30 seconds unless the server is created with another, and
this one asks for half a second. That is why the answer came a little after the two seconds rather
than on them, and why, with the default, a two-second timeout can take up to thirty-two.

In production the defaults are a reasonable start, and a proxy in front of
Node, which `servers-cache` sets up, usually enforces tighter ones before a slow client ever reaches
it. What matters is knowing they exist, so that a long upload that fails at exactly five minutes is
recognised as `requestTimeout` and not hunted for in your code.
