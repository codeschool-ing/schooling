---
title: Monotonic reads: time that does not go backwards
version: 1
---

Two copies are rarely at the same point in the stream, and a load balancer does not care which one a
request reaches. A customer looks at the coffee half a second after it changed to 7, and reloads the page half a second
after that:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 7
coffee: 7 in stock, version 14
ana@vm:~/lab/eventual$ sleep 0.5; curl -s localhost:8002/product/coffee; sleep 0.5; curl -s localhost:8003/product/coffee
shop-a: coffee: 7 left, version 14
shop-b: coffee: 0 left, version 13
```

The first answer came from shop `a`, which already had version 14, and the second from shop `b`, still
at version 13. Each answer was true at some moment. Put together in that order, **the coffee went from
7 back to 0**, which is not something that ever happened. The customer may have added a bag to the
basket on the first page and been told on the second that there is none.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A customer reloads a product page twice. A load balancer sends the first request to shop a, whose copy is at version 14 and answers 7 left. It sends the second to shop b, whose copy is at version 13 and answers 0 left. To the customer the stock went from 7 back to 0, which never happened in that order.\"><defs><marker id=\"l9-monotonic-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9-monotonic-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l9-monotonic-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"105\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">customer</text><rect x=\"220\" y=\"105\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">balancer</text><rect x=\"430\" y=\"40\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"510\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop a</text><text x=\"510\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">version 14: 7</text><rect x=\"430\" y=\"154\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"510\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop b</text><text x=\"510\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">version 13: 0</text><path d=\"M152 125 L218 125\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-monotonic-ah-wire)\"></path><path d=\"M342 115 L428 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-monotonic-ah-phosphor)\"></path><path d=\"M342 135 L428 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-monotonic-ah-amber)\"></path><text x=\"370\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1st</text><text x=\"370\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2nd</text><text x=\"650\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">7 left</text><text x=\"650\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">0 left</text><text x=\"90\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sees 7, then 0</text></svg>", "caption": "Two copies at different points in the stream. Each answer is a value that was once true, and together, in this order, they tell a story that never happened."}
```

The guarantee that rules this out is **monotonic reads**: once a person has seen a version, they never
see an older one. Again it is a promise to one person, and again it is cheap. There are two ways to
keep it:

- **Stick the person to one copy.** If every request from one session reaches the same copy, the
  versions they see can only go forward. Load balancers call it session affinity, or sticky sessions.
  It breaks when that copy is restarted or removed, and it spreads load unevenly.
- **Remember the highest version seen**, and send it with every read, exactly as in the previous
  section. A copy that is behind it asks the owner, or waits until it catches up:

```
ana@vm:~/lab/eventual$ curl -s 'localhost:8003/product/coffee?after=14'
shop-b: coffee: 7 in stock, version 14 (copy behind, asked the stock service)
```

One mechanism, a version that travels with the person, gives both session guarantees: read-your-writes
when the version came from their own write, and monotonic reads when it came from their last read.
**A version number in the data is cheap to add on the first day and very hard to add later**, after
every event and every copy has been designed without it. The next section shows that the copy needs it
too, for a reason that has nothing to do with the reader.
