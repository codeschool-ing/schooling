---
title: One id per request, end to end
version: 1
---

With one person clicking, a log reads like a story. With fifty requests a second it reads like fifty
stories shuffled together, and the question support actually asks, "what happened to this customer's
checkout?", has no answer in it. The thread name looks like a way to tell them apart and is not:
Tomcat serves requests from a pool of threads, so `nio-8080-exec-9` handles one request, then
another, then a thousand more.

What separates them is a **request id**: a short value given to each request on the way in, written
on every line that request causes, and returned to the caller so that a person holding a failed
response can quote it. Getting it onto every line without passing it to every method is the job of
the **MDC**, the Mapped Diagnostic Context: a small map that belongs to the current thread, which
SLF4J lets you fill and the backend reads each time it writes a line.

## The filter

Create `src/main/java/com/example/bookshop/web/RequestIdFilter.java`:

@@EX filter@@

The last line of `application.properties`, added in the previous section, is the other half:

```properties
logging.pattern.correlation=[%X{requestId:-}]
```

`%X{requestId}` is Logback's way of reading the MDC key `requestId`, and `:-` with nothing after it
says what to print when the key is missing: nothing. Boot puts this pattern after the thread name in
every line, which is the `[]` the start-up lines carried. Package again, and restart the second
terminal:

```
ana@vm:~/bookshop$ mvn -q package
```

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar > app.log
```

## Following one request

The header comes back on every response. Without one the filter makes an id up; with a sensible one
it keeps it; with one it does not trust it replaces it; and a request that Spring Security turns away
still has one, because the filter runs first:

```
ana@vm:~/bookshop$ curl -si localhost:8080/books/1 | grep -iE '^(HTTP|X-Request-Id)'
HTTP/1.1 200 
X-Request-Id: a2427a7e
ana@vm:~/bookshop$ curl -si -H 'X-Request-Id: checkout-41' localhost:8080/books/1 | grep -iE '^(HTTP|X-Request-Id)'
HTTP/1.1 200 
X-Request-Id: checkout-41
ana@vm:~/bookshop$ curl -si -H 'X-Request-Id: two words' localhost:8080/books/1 | grep -iE '^(HTTP|X-Request-Id)'
HTTP/1.1 200 
X-Request-Id: 29aba6be
ana@vm:~/bookshop$ curl -si -X POST localhost:8080/orders | grep -iE '^(HTTP|X-Request-Id)'
HTTP/1.1 401 
X-Request-Id: 6bd16e4a
```

**Why refuse `two words` rather than log it?** Because whatever is in that header would be copied into
the log, and the log is read by people and parsed by programs that trust it. A header carrying a line
break could add a line of its own, with a timestamp and a level that the application never wrote.
The filter accepts only what a request id needs to be, and that leaves nothing to forge with.

Now an order, with the token lesson 15 showed how to get:

```
ana@vm:~/bookshop$ TOKEN=$(curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])')
ana@vm:~/bookshop$ curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -H 'X-Request-Id: checkout-42' -d '{"lines":[{"bookId":2,"quantity":1}]}' localhost:8080/orders; echo
{"id":1,"customer":"ana","placedAt":"2026-10-16T23:30:37Z","lines":[{"bookId":2,"title":"The Time Machine","quantity":1,"priceCents":2950}],"totalCents":2950}
ana@vm:~/bookshop$ grep checkout-42 app.log
2026-10-16T20:30:37.719-03:00  INFO 24749 --- [bookshop] [nio-8080-exec-9] [checkout-42] c.e.bookshop.ordering.OrderService       : Order 1 placed by ana: 1 line(s), 2950 cents
```

`OrderService` never mentions a request id, and its line carries one. Every other line written on
that thread while the request was in progress, by the bookshop, by Spring or by Hibernate, would carry
it too, and `grep checkout-42` finds them all. (Your order id will differ from this one, which ran on
a fresh database.)

@@FIG ids@@

## Where the id stops

The MDC belongs to a thread, and that is both why it works and where it ends. Work handed to another
thread, an `@Async` method or a `CompletableFuture` on a pool, starts with that thread's MDC, which
is empty, and its lines show `[]`. SLF4J lets you carry it across by hand:
`MDC.getCopyOfContextMap()` before the hand-over and `MDC.setContextMap(...)` at the start of the
work.

And the id stops at the edge of this application. If the bookshop called another service, that
service would make up its own id unless the bookshop sent `X-Request-Id` along. Doing that for every
outgoing call, across many services, is what distributed tracing does, with Micrometer Tracing on
Spring's side; when it is on the classpath, Boot fills this same correlation slot with a trace id and
a span id. For one application, the filter above is the whole of it.
