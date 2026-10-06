---
title: A debugger, through a port
version: 1
---

**A debugger attaches to a running program over a connection, and in a container that connection is
one more port.** Node has one built in: `--inspect` opens a debugging endpoint that Chrome's developer
tools and VS Code both speak.

```
ana@vm:~$ docker run -d --name hello -v "$PWD/hello":/app -w /app -p 127.0.0.1:3000:3000 -p 127.0.0.1:9229:9229 node:24-alpine node --watch --inspect=0.0.0.0:9229 server.js
341c613ed741d55966b4fcd68c8b8551cd1a97532adde8d3cf92ad9dc97a61c2
ana@vm:~$ docker logs hello 2>&1 | head -2
Debugger listening on ws://0.0.0.0:9229/c2189153-c10b-4126-9732-df71aed83d0c
For help, see: https://nodejs.org/learn/getting-started/debugging
ana@vm:~$ curl -s localhost:9229/json/list | jq ".[] | {title, url, webSocketDebuggerUrl}"
{
  "title": "server.js",
  "url": "file:///app/server.js",
  "webSocketDebuggerUrl": "ws://localhost:9229/c2189153-c10b-4126-9732-df71aed83d0c"
}
```

Two details make it reachable, and one keeps it safe:

- **`--inspect=0.0.0.0:9229` inside the container.** By default Node listens for the debugger on
  `127.0.0.1`, and inside a container that is the container's own loopback (lesson 23), which a
  published port never reaches.
- **`-p 127.0.0.1:9229:9229` on the host.** The endpoint is listed at `/json/list`, with the WebSocket
  address an editor connects to.
- **The host side stays on the loopback address.** A debugger can read any variable and run any code
  in the program: an open debugging port on a network address hands that to anybody who can reach it.
  It is a development flag, and it never appears in the image or the Compose file that ships.

Attaching is then done from the editor: VS Code's "Attach" configuration with port 9229, or Chrome's
`chrome://inspect`, both pointed at `localhost:9229`. **That step was not run in the lab**, which has
no graphical editor; what the capture shows is the endpoint they connect to.

## For Go

Go's debugger is **Delve**, `dlv`, and it works the same way: `dlv debug --headless --listen=:2345`
inside a development container built from `golang:1.25` with Delve installed, the port published on
the loopback address, and the editor attaching to it. It was not run here either, since installing
Delve needs the network the lab's containers lack. `dlv debug` compiles the program itself, without
optimisations, so that variables are not optimised away and lines map to what the debugger shows. A
binary built that way is slower and larger, which is one more reason a debugging setup lives in a
development file and never in the image that ships.
