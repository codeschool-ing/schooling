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
the **MDC**, the Mapped Diagnostic Context. It is a small map that belongs to the current thread:
SLF4J lets you fill it, and the backend reads it each time it writes a line.

## The filter

Create `src/main/java/com/example/bookshop/web/RequestIdFilter.java`:

```schooling-example
{"language": "java", "file": "RequestIdFilter.java", "parts": [{"code": "package com.example.bookshop.web;\n\nimport java.io.IOException;\nimport java.util.UUID;\n\nimport jakarta.servlet.FilterChain;\nimport jakarta.servlet.ServletException;\nimport jakarta.servlet.http.HttpServletRequest;\nimport jakarta.servlet.http.HttpServletResponse;\n\nimport org.slf4j.MDC;\nimport org.springframework.core.Ordered;\nimport org.springframework.core.annotation.Order;\nimport org.springframework.stereotype.Component;\nimport org.springframework.web.filter.OncePerRequestFilter;\n"}, {"code": "@Component\n@Order(Ordered.HIGHEST_PRECEDENCE)\npublic class RequestIdFilter extends OncePerRequestFilter {\n", "note": "A `@Component` filter is registered by Boot for every request, and `OncePerRequestFilter` runs it once per request even when the request is forwarded inside the server. `HIGHEST_PRECEDENCE` puts it before Spring Security's filters, so a request refused with 401 gets an id as well."}, {"code": "    static final String HEADER = \"X-Request-Id\";\n"}, {"code": "    @Override\n    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)\n            throws ServletException, IOException {"}, {"code": "        String id = request.getHeader(HEADER);\n        if (id == null || !id.matches(\"[A-Za-z0-9-]{1,64}\")) {\n            id = UUID.randomUUID().toString().substring(0, 8);\n        }", "note": "Use the caller's id if it has one and it is short, plain letters, digits and hyphens. Anything else is replaced by eight characters of a random UUID: a value from outside is never written into the log as it came."}, {"code": "        MDC.put(\"requestId\", id);\n        response.setHeader(HEADER, id);", "note": "`MDC.put` attaches the id to this thread, and the same id goes back to the caller in the response header."}, {"code": "        try {\n            chain.doFilter(request, response);\n        } finally {\n            MDC.remove(\"requestId\");\n        }\n    }\n}", "note": "The rest of the chain runs with the id in place. `finally` takes it off again whatever happens, because Tomcat hands this thread to another request next."}]}
```

The last line of `application.properties`, added in the previous section, is the other half:

```properties
logging.pattern.correlation=[%X{requestId:-}] 
```

`%X{requestId}` is Logback's way of reading the MDC key `requestId`, and `:-` with nothing after it
says what to print when the key is missing: nothing. Boot puts this pattern after the thread name in
every line, which is the `[]` the start-up lines carried. **The line ends in a space**, invisible above
and part of the value: Boot places the pattern directly against the logger's name, and without the
space the two would run together. Package again, and restart the second
terminal:

```
ana@vm:~/bookshop$ mvn -q package
```

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar > app.log
```

## Following one request

The header comes back on every response. A request without one gets an id made up, and a sensible
one is kept. One the filter does not trust is replaced. A request that Spring Security turns away
still gets an id, because the filter runs first:

```
ana@vm:~/bookshop$ curl -si localhost:8080/books/1 | grep -iE '^(HTTP|X-Request-Id)'
HTTP/1.1 200 
X-Request-Id: 85b598d4
ana@vm:~/bookshop$ curl -si -H 'X-Request-Id: checkout-41' localhost:8080/books/1 | grep -iE '^(HTTP|X-Request-Id)'
HTTP/1.1 200 
X-Request-Id: checkout-41
ana@vm:~/bookshop$ curl -si -H 'X-Request-Id: two words' localhost:8080/books/1 | grep -iE '^(HTTP|X-Request-Id)'
HTTP/1.1 200 
X-Request-Id: 1a1c6767
ana@vm:~/bookshop$ curl -si -X POST localhost:8080/orders | grep -iE '^(HTTP|X-Request-Id)'
HTTP/1.1 401 
X-Request-Id: 82327b57
```

**Why refuse `two words` rather than log it?** Because whatever is in that header would be copied into
the log, and the log is read by people and parsed by programs that trust it. A header carrying a line
break could add a line of its own, with a timestamp and a level that the application never wrote.
The filter accepts only what a request id needs to be, and that leaves nothing to forge with.

Now an order, with a token from lesson 15's `/auth/token`:

```
ana@vm:~/bookshop$ TOKEN=$(curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])')
ana@vm:~/bookshop$ curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -H 'X-Request-Id: checkout-42' -d '{"lines":[{"bookId":2,"quantity":1}]}' localhost:8080/orders; echo
{"id":1,"customer":"ana","placedAt":"2026-10-22T22:32:44Z","lines":[{"bookId":2,"title":"The Time Machine","quantity":1,"priceCents":2950}],"totalCents":2950}
ana@vm:~/bookshop$ grep checkout-42 app.log
2026-10-22T19:32:44.986-03:00  INFO 21495 --- [bookshop] [nio-8080-exec-9] [checkout-42] c.e.bookshop.ordering.OrderService       : Order 1 placed by ana: 1 line(s), 2950 cents
```

`OrderService` never mentions a request id, and its line carries one. Every other line written on
that thread while the request was in progress, by the bookshop, by Spring or by Hibernate, would carry
it too, and `grep checkout-42` finds them all. (Your order id will differ from this one, which ran on
a fresh database.)

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A sequence in four columns. curl sends X-Request-Id: checkout-42 to RequestIdFilter, which puts it in the MDC and sets the response header, then calls the rest of the chain. OrderService logs, and the line in the log carries checkout-42. The chain returns, the filter removes the id from the MDC, and the response reaches curl carrying the header.\"><defs><marker id=\"fid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"0\" y=\"10\" width=\"140\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><line x1=\"70\" y1=\"42\" x2=\"70\" y2=\"345\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><rect x=\"180\" y=\"10\" width=\"140\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RequestIdFilter</text><line x1=\"250\" y1=\"42\" x2=\"250\" y2=\"345\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><rect x=\"380\" y=\"10\" width=\"140\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the rest of the chain</text><line x1=\"450\" y1=\"42\" x2=\"450\" y2=\"345\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><rect x=\"560\" y=\"10\" width=\"140\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the log</text><line x1=\"630\" y1=\"42\" x2=\"630\" y2=\"345\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><line x1=\"70\" y1=\"70\" x2=\"248\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fid-ah)\"></line><text x=\"160\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">X-Request-Id: checkout-42</text><rect x=\"165\" y=\"84\" width=\"170\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MDC.put(requestId)</text><text x=\"250\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">read it, or make one</text><rect x=\"165\" y=\"128\" width=\"170\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">response.setHeader</text><text x=\"250\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">before the response is written</text><line x1=\"250\" y1=\"186\" x2=\"448\" y2=\"186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fid-ah)\"></line><text x=\"350\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">chain.doFilter</text><line x1=\"450\" y1=\"216\" x2=\"628\" y2=\"216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fid-ah)\"></line><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">log.info(...)</text><rect x=\"560\" y=\"226\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">[checkout-42] Order 1</text><text x=\"635\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">every line on this thread</text><line x1=\"448\" y1=\"280\" x2=\"252\" y2=\"280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fid-ah)\"></line><rect x=\"165\" y=\"290\" width=\"170\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"303\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MDC.remove(requestId)</text><text x=\"250\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the pooled thread is clean again</text><line x1=\"165\" y1=\"338\" x2=\"72\" y2=\"338\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fid-ah)\"></line><text x=\"115\" y=\"326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the response, with the header</text></svg>", "caption": "The id lives on the thread from MDC.put to MDC.remove, and every line logged in between carries it, whoever writes it."}
```

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
