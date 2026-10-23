---
title: One servlet in front of every controller
version: 1
---

It is natural to picture Tomcat calling `BookController`, or each controller listening for its own
paths. Neither happens. Tomcat runs servlets, the Jakarta standard for an object that takes an
HTTP request and writes a response, and in this application it knows exactly one: the
**`DispatcherServlet`** that Spring Boot's autoconfiguration registered in lesson 4. Every request
goes to it, and it decides which of your methods answers. The pattern has a name, **front
controller**: one entrance, with the routing behind it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 340\" role=\"img\" aria-label=\"curl sends GET /books/2 to Tomcat, which hands it to the one DispatcherServlet. Inside it, four steps in order: find the method (RequestMappingHandlerMapping), resolve the arguments (the path text 2 becomes a long), call BookController.get, and write the returned BookResponse as JSON with Jackson. The answer, status 200 with a JSON body, goes back to curl.\"><defs><marker id=\"l6d-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><text x=\"80\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the client</text><rect x=\"180\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Tomcat</text><text x=\"240\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the server</text><line x1=\"140\" y1=\"65\" x2=\"178\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><text x=\"159\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /books/2</text><rect x=\"340\" y=\"14\" width=\"345\" height=\"316\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"512\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DispatcherServlet</text><text x=\"512\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one servlet, every request</text><line x1=\"300\" y1=\"65\" x2=\"338\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><rect x=\"360\" y=\"70\" width=\"305\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"374\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1</text><text x=\"390\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">find the method</text><text x=\"390\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">RequestMappingHandlerMapping</text><text x=\"390\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /books/2 belongs to BookController#get</text><line x1=\"512\" y1=\"124\" x2=\"512\" y2=\"133\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><rect x=\"360\" y=\"134\" width=\"305\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"374\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">2</text><text x=\"390\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resolve the arguments</text><text x=\"390\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">@PathVariable long id</text><text x=\"390\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the text \"2\" from the path becomes the long 2</text><line x1=\"512\" y1=\"188\" x2=\"512\" y2=\"197\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><rect x=\"360\" y=\"198\" width=\"305\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"374\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3</text><text x=\"390\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">call the method</text><text x=\"390\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">BookController#get(long)</text><text x=\"390\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">your code: the service, an Optional, a status</text><line x1=\"512\" y1=\"252\" x2=\"512\" y2=\"261\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><rect x=\"360\" y=\"262\" width=\"305\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"374\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">4</text><text x=\"390\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">write the return value</text><text x=\"390\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">BookResponse</text><text x=\"390\" y=\"307\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jackson turns the record into JSON</text><path d=\"M 360 291 L 80 291 L 80 92\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></path><text x=\"215\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">200, Content-Type: application/json, the JSON body</text></svg>", "caption": "Tomcat knows one servlet. Everything the bookshop answers goes through these four steps, and only the third is code you wrote."}
```

The four steps, in the order they run:

1. **Find the method.** At start-up, Spring reads the `@RequestMapping` and `@GetMapping` annotations of
   every controller bean and builds a table from a method and a path pattern to a Java method. Each
   request is looked up in that table. The 405 and the 404 of the previous section came from this
   lookup: a path that matches for another method, and a path that matches nothing.
2. **Resolve the arguments.** Each parameter is filled by a resolver chosen by its annotation.
   `@PathVariable` converts a piece of the path; `@RequestBody`, in the section on POST, reads the
   body with a **message converter**. When a conversion fails, the method never runs, which is what
   happened to `/books/abc`.
3. **Call the method.** This is the only step that is your code.
4. **Write the return value.** A message converter turns what the method returned into the body,
   chosen by **content negotiation**: what the client says it accepts against what the converters can
   write. A `ResponseEntity` adds the status and the headers.

## Watching it happen

The `dev` profile that lesson 4 wrote sets `logging.level.org.springframework.web=debug`, which makes
the `DispatcherServlet` narrate, and moves the port to 8081. Stop the application and start it with
the profile:

```sh
java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dev
```

Ask for a book on the new port:

```
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8081/books/2
{"id":2,"isbn":"9786500000023","title":"The Time Machine","author":"H. G. Wells","priceCents":2950}
```

The second terminal printed these lines among many others. The start-up lines around them are left
out here:

```
2026-10-16T20:31:56.197-03:00 DEBUG 31546 --- [bookshop] [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : 4 mappings in 'requestMappingHandlerMapping'
2026-10-16T20:31:57.074-03:00  INFO 31546 --- [bookshop] [nio-8081-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2026-10-16T20:31:57.087-03:00 DEBUG 31546 --- [bookshop] [nio-8081-exec-1] o.s.web.servlet.DispatcherServlet        : GET "/books/2", parameters={}
2026-10-16T20:31:57.125-03:00 DEBUG 31546 --- [bookshop] [nio-8081-exec-1] s.w.s.m.m.a.RequestMappingHandlerMapping : Mapped to com.example.bookshop.catalogue.BookController#get(long)
2026-10-16T20:31:57.192-03:00 DEBUG 31546 --- [bookshop] [nio-8081-exec-1] o.s.w.s.m.m.a.HttpEntityMethodProcessor  : Using 'application/json', given [*/*] and supported [application/json, application/*+json]
2026-10-16T20:31:57.220-03:00 DEBUG 31546 --- [bookshop] [nio-8081-exec-1] o.s.w.s.m.m.a.HttpEntityMethodProcessor  : Writing [BookResponse[id=2, isbn=9786500000023, title=The Time Machine, author=H. G. Wells, priceCents=2950]]
2026-10-16T20:31:57.265-03:00 DEBUG 31546 --- [bookshop] [nio-8081-exec-1] o.s.web.servlet.DispatcherServlet        : Completed 200 OK
```

Each line is one of the steps in the figure:

- `4 mappings in 'requestMappingHandlerMapping'` is the table of step 1, built at start-up: your two
  methods and two that Spring Boot adds for its own `/error` path, the one that wrote the body for
  `/authors`.
- `Initializing Servlet 'dispatcherServlet'` appears at the first request and not at start-up: Spring
  created the servlet while starting, and Tomcat initialises it the first time it is needed.
- `GET "/books/2"` and `Mapped to com.example.bookshop.catalogue.BookController#get(long)` are step 1
  at work for this request.
- `Using 'application/json', given [*/*] and supported [...]` is step 4's negotiation. curl sends
  `Accept: */*`, meaning anything will do, and the only converters able to write a `BookResponse`
  produce JSON.
- The `Writing` line shows the record as its own `toString` prints it, just before the converter
  turns it into JSON. `Completed 200 OK` is the end.

## What sits around it

The `DispatcherServlet` is not the first code a request meets. In front of it is a chain of servlet
**filters**, which see every request before any controller does: lesson 15 puts Spring Security
there, and lesson 16 adds a filter that labels each request with an id. Behind it, when a method
throws an exception, the dispatcher asks its exception resolvers what to answer; one of them wrote
the 400 for `/books/abc`, and lesson 7 gives them answers of your own.
