---
title: More than one server
version: 1
---

Every technique so far was tried against instance `a` alone. A real shop runs several instances behind a
load balancer, and a long-held connection lands on one of them. Connect the WebSocket client to instance
`b`, and have the warehouse publish to instance `a`:

```
ana@vm:~/lab/live$ $W ws://live-b:8000/ws 3 & sleep 1.5; curl -s -X POST localhost:8001/publish -d "o-2 paid"; wait
b: received 'hello'
a: published
```

The client said hello to `b` and `b` answered. The event went to `a`, and `a` told only its own
clients; `b` never heard of it, and the customer's page never changed. Nothing failed, so nothing was
logged. With two instances half the customers miss half the events; with ten, nine in ten.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two instances of the order-status service behind a load balancer. A customer&#x27;s WebSocket is connected to instance b. The warehouse publishes an event to instance a. Without a backplane, the event stays on a and the customer hears nothing. With a backplane, a publishes to Redis, Redis delivers to both a and b, and b pushes it to the customer.\"><defs><marker id=\"l18-backplane-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l18-backplane-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">warehouse</text><rect x=\"260\" y=\"40\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instance a</text><rect x=\"260\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instance b</text><rect x=\"540\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">customer</text><rect x=\"540\" y=\"40\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Redis</text><path d=\"M182 65 L258 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-backplane-ah-wire)\"></path><text x=\"220\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">publish</text><path d=\"M538 183 L412 183\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"475\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">WebSocket</text><path d=\"M412 65 L538 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-backplane-ah-phosphor)\"></path><path d=\"M560 92 L380 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-backplane-ah-phosphor)\"></path><path d=\"M412 208 L538 208\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-backplane-ah-phosphor)\"></path><text x=\"540\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">to every instance</text><text x=\"335\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">without: stops here</text><path d=\"M335 92 L335 116\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "With more than one instance, the event and the connection can be on different servers. A backplane delivers every event to every instance."}
```

The fix is a **backplane**: a publish and subscribe channel that every instance listens to. An instance
that receives an event does not add it itself; it publishes it to the backplane, and every instance,
itself included, receives it and pushes it to its own clients. Redis's pub/sub is the usual choice, and
the lab's service has it built in. Restart both instances with it on, and repeat:

```
ana@vm:~/lab/live$ BACKPLANE=redis://redis:6379 docker compose up -d
 Container live-redis-1 Running 
 Container live-live-a-1 Recreate 
 Container live-live-b-1 Recreate 
 Container live-live-a-1 Recreated 
 Container live-live-b-1 Recreated 
 Container live-live-b-1 Starting 
 Container live-live-a-1 Starting 
 Container live-live-b-1 Started 
 Container live-live-a-1 Started 
ana@vm:~/lab/live$ $W ws://live-b:8000/ws 3 & sleep 1.5; curl -s -X POST localhost:8001/publish -d "o-2 paid"; wait
b: received 'hello'
a: published
b: o-2 paid
```

`b` pushed the event that `a` received. This is what SignalR's Redis backplane and Socket.IO's Redis
adapter do. Lesson 6's brokers would serve too.

Long-held connections change a few other things about running a service:

- **Each connection costs memory and a file descriptor**, for as long as the customer keeps the page
  open. An asynchronous server, like the lab's, holds tens of thousands per instance; a thread per
  connection would not.
- **A deploy ends every connection.** Instances should drain: stop accepting new connections, tell
  clients to reconnect elsewhere, and only then stop, or a release becomes a reconnection storm, lesson
  11's retry storm on a different protocol.
- **Load balancing is uneven.** A balancer spreads new connections, but connections live for hours, so
  a new instance stays empty while the old ones stay full until clients reconnect.
