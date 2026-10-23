---
title: Four ways to hear about a change
version: 1
---

Every answer boxoffice has given so far was asked for. A page that says "112 seats left" was true the
moment the browser fetched it, and on the night a concert sells out it stops being true within seconds.
The server cannot call the browser. Either the browser keeps asking, or it keeps a line open for the
server to talk down.

There are four ways to arrange that, and they differ in who pays and how much:

| technique | how it works | what it costs | direction |
|---|---|---|---|
| **polling** | the page asks again every few seconds | a request per visitor per interval, most of them answered with the number they already had, and news up to one interval late | the client asks |
| **long polling** | the page asks, and the server holds the request until something changes or a timeout passes; then the page asks again | one waiting request per visitor, and a new request after every change | the server answers when it has news |
| **server-sent events** | one `GET` whose response never ends; the server writes a line whenever there is news | one open connection per visitor, over plain HTTP, text only; the browser reconnects by itself | server to client |
| **WebSocket** | an HTTP request that turns into a two-way channel of messages | one open connection per visitor, a protocol of its own after the first request, and reconnecting is your code's job | both ways |

Polling is worth the arithmetic. Two thousand people on an event page, each asking every two seconds, is
a thousand requests a second, and between sales nearly all of them get the same number back. It is the
right answer more often than its reputation suggests: a dashboard refreshed every minute by a dozen staff
needs nothing more, and it has no connection to keep alive. Two seconds of lag and a thousand empty
answers a second are the price it charges when the audience is large and the news is urgent.

**Seat availability flows one way**, from the server to whoever is looking, so server-sent events cover it
completely. A WebSocket earns its extra machinery when the client talks back constantly: a chat, a game, a
document several people edit at once. This lesson builds both over the same source of news, in sections
04 and 05, so the difference is in the handler and not in the data. Sections 06 and 07 hand the
WebSocket work to a library and then to a separate server.

## A connection that stays open

The last three techniques keep something open per visitor, and in Go that is the ordinary case rather
than a special one: lesson 1's server already gives every connection a goroutine of its own. Ten
thousand open connections are ten thousand goroutines mostly asleep, waiting for something to write.

Two limits sit outside the program. A browser speaking HTTP/1.1 opens at most six connections to one
site, and every tab holding a server-sent event stream uses one of them; over HTTP/2 the streams share a
single connection and the limit disappears. And anything between the browser and the server, such as a
proxy or a load balancer, has opinions about connections that sit quiet, which section 08 deals with.

The connection was never the hard part. **The hard part is knowing that something changed**, and that is
the next section.
