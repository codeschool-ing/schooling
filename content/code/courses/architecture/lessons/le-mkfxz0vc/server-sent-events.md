---
title: Server-Sent Events
version: 1
---

**Server-Sent Events** turn the response itself into the channel. The browser makes one request with
`Accept: text/event-stream`, and the server answers with a response that never ends, writing each event
into it as a few lines of text: an `id:` line, a `data:` line, and a blank line to close it. Open the
stream for four seconds while the warehouse marks the order shipped:

```
ana@vm:~/lab/live$ timeout 4 curl -sN localhost:8001/events & sleep 1; curl -s -X POST localhost:8001/publish -d "o-1 shipped" > /dev/null; wait
id: 1
data: a: o-1 paid

id: 2
data: a: o-1 packed

id: 3
data: a: o-1 shipped
```

The stream first sent the two events that already existed, then held still, then wrote event 3 the
moment it was published. In a browser the whole client is two lines of JavaScript,
`new EventSource("/events")` and a handler for its messages, and the browser handles what most code gets
wrong: **it reconnects on its own**, and when it does, it sends the id of the last event it received in
a `Last-Event-ID` header. The server starts the stream after that one:

```
ana@vm:~/lab/live$ timeout 2 curl -sN localhost:8001/events -H "Last-Event-ID: 2"
id: 3
data: a: o-1 shipped
```

Asked to resume after event 2, the stream sent event 3 and nothing before it. A dropped connection on a
train costs the customer nothing.

SSE is plain HTTP, so it passes through proxies, load balancers and corporate firewalls that understand
HTTP, it works with HTTP/2 and HTTP/3, and it is compressed and authenticated like any other response.
Its limits are that it carries **text, from the server only**, and that on HTTP/1.1 a browser opens at
most six connections to one host, which several tabs with a stream each can use up; on HTTP/2 the
streams share one connection and the limit disappears. For "tell the page when something changes",
which is most of what a shop needs, it is usually the right answer and the most often overlooked.
