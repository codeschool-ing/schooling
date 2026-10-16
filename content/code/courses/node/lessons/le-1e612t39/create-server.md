---
title: Listening on a port
version: 1
---

**`http.createServer(handler)` makes a server, and `server.listen(port, host)` opens the port.** The
first returns at once and opens nothing; the second asks the operating system for the port, and the
callback runs when it has it. Every project in `~/server/native` says `"type": "module"`, so make
that its `package.json` before anything else:

```
ana@dev:~/server/native$ echo '{ "name": "native", "private": true, "type": "module" }' > package.json
```

```javascript
// listen.js
import http from "node:http";

const server = http.createServer((req, res) => res.end("hello\n"));

server.listen(Number(process.argv[2] ?? 3000), process.argv[3] ?? "127.0.0.1", () => {
  console.log("listening on", server.address());
});
```

## Which address

The host decides **who can reach the server**, and it is the most consequential argument in this
lesson:

| host | who can connect |
|---|---|
| `127.0.0.1` | only programs on this computer |
| `0.0.0.0` | anybody who can reach any address this computer has, on any network it is on |
| leave it out | Node listens on every address, IPv6 included, the same as `0.0.0.0` and wider |

**Every server in this course listens on `127.0.0.1`.** A development server on `0.0.0.0` on a laptop
in a café is a server anybody in the café can talk to, with whatever debugging routes it has. In
production a process usually sits behind a proxy on the same machine, and listens on `127.0.0.1` for
it, which the `servers-cache` course sets up; inside a container it must listen on `0.0.0.0`, because
the container's own loopback is not where requests arrive, and the `docker` course says why.

## Port 0

Port 0 means *any free port*, and the operating system picks one:

```
ana@dev:~/server/native$ node listen.js 0
listening on { address: '127.0.0.1', family: 'IPv4', port: 35755 }
^C
```

`server.address()` says which port was given. A test uses this, so that two test files running at
once never fight over port 3000. Ports below 1024 need root on Linux, which is why development
servers live at 3000 and 8080 rather than 80. `Ctrl-C` stops it.
