---
title: WebSockets
version: 1
---

A **WebSocket** starts as an HTTP request with `Upgrade: websocket`. The server agrees with a
`101 Switching Protocols`, and from then on the TCP connection is no longer HTTP: it is a channel of
messages, text or binary, that **either side can send on at any time**. Connect the client, which says
hello, and publish an event while it listens:

```
ana@vm:~/lab/live$ $W ws://live-a:8000/ws 3 & sleep 1.5; curl -s -X POST localhost:8001/publish -d "o-1 out for delivery" > /dev/null; wait
a: received 'hello'
a: o-1 out for delivery
```

The server answered the client's message, then pushed the event the moment it arrived. That two-way part
is what WebSockets are for: chat, collaborative editing, multiplayer games, a live auction where every
bid goes both ways. For an order-status page, which only listens, it does nothing SSE does not.

And it costs more to run, because it has stepped outside HTTP:

- **Reconnecting is your job.** The browser's `WebSocket` does not reconnect, and there is no
  `Last-Event-ID`; the application has to notice a dropped connection, reconnect with backoff, and ask
  for what it missed.
- **Idle connections get cut.** Load balancers and proxies close connections that are quiet for a while,
  often 60 seconds. Both sides send **pings** to keep it alive and to notice a dead peer; the lab's
  server pings every 20 seconds (`heartbeat=20`).
- **Every layer must let it through.** Some proxies and corporate networks block the upgrade, which is
  why libraries such as Socket.IO and SignalR fall back to long polling.
- **No HTTP caching, compression or status codes** on the messages; anything like them is built by the
  application.
