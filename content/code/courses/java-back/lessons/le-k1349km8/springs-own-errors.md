---
title: Spring's own errors, in the same shape
version: 1
---

Some errors happen before any code of the bookshop runs: the body is not JSON, the path matches no
controller, the method is one the path does not take. Spring MVC raises exceptions of its own for these,
and lesson 6's bookshop answered them with Spring Boot's error page, in its own shape:

```
ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "title": ' -w '\n'
HTTP/1.1 400 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:22 GMT
Connection: close

{"timestamp":"2026-10-16T23:42:22.353Z","status":400,"error":"Bad Request","path":"/books"}
ana@vm:~/bookshop$ curl -si localhost:8080/nope -w '\n'
HTTP/1.1 404 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:22 GMT

{"timestamp":"2026-10-16T23:42:22.385Z","status":404,"error":"Not Found","path":"/nope"}
```

Two shapes in one API is worse than either of them alone. A client that reads `type` and `detail` from
one 400 and finds `timestamp` and `error` in the next has to handle both, and nothing tells it which to
expect.

**`ResponseEntityExceptionHandler`** is the fix, and it is why `ApiErrorHandler` extends it. The class is
Spring's. It carries an `@ExceptionHandler` for the exceptions Spring MVC raises itself, and each one
answers with a `ProblemDetail`. Extending it puts all of them inside the bookshop's advice, beside the
bookshop's own handlers. Ask the rebuilt bookshop the same kinds of thing, and a few more:

```
ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "title": ' -w '\n'
HTTP/1.1 400 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:38 GMT
Connection: close

{"detail":"Failed to read request","instance":"/books","status":400,"title":"Bad Request"}
ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "priceCents": "cheap"}' -w '\n'
HTTP/1.1 400 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:38 GMT
Connection: close

{"detail":"Failed to read request","instance":"/books","status":400,"title":"Bad Request"}
ana@vm:~/bookshop$ curl -si localhost:8080/books/abc -w '\n'
HTTP/1.1 400 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:38 GMT
Connection: close

{"detail":"Failed to convert 'id' with value: 'abc'","instance":"/books/abc","status":400,"title":"Bad Request"}
ana@vm:~/bookshop$ curl -si localhost:8080/nope -w '\n'
HTTP/1.1 404 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:38 GMT

{"detail":"No static resource nope.","instance":"/nope","status":404,"title":"Not Found"}
ana@vm:~/bookshop$ curl -si -X DELETE localhost:8080/books/1 -w '\n'
HTTP/1.1 405 
Allow: GET
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:38 GMT

{"detail":"Method 'DELETE' is not supported.","instance":"/books/1","status":405,"title":"Method Not Allowed"}
ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: text/plain' -d 'hello' -w '\n'
HTTP/1.1 415 
Accept: application/json, application/*+json
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:38 GMT

{"detail":"Content-Type 'text/plain;charset=UTF-8' is not supported.","instance":"/books","status":415,"title":"Unsupported Media Type"}
```

Every answer is `application/problem+json` now, and each status is the one HTTP has for the case:

| what the client sent | status | the exception Spring MVC raised |
|---|---|---|
| a body that is not JSON, or a value of the wrong type | 400 | `HttpMessageNotReadableException` |
| a path variable that does not convert, `/books/abc` | 400 | `MethodArgumentTypeMismatchException` |
| a path no controller maps | 404 | `NoResourceFoundException` |
| a method the path does not take | 405 | `HttpRequestMethodNotSupportedException` |
| a `Content-Type` nothing can read | 415 | `HttpMediaTypeNotSupportedException` |

The 405 and the 415 carry a header as well, because HTTP asks for one. `Allow: GET` lists the methods
`/books/1` takes, and `Accept` lists the media types `/books` can read. The 404 for `/nope` mentions a
static resource because of how Spring MVC searches: a path no controller maps is offered last to the
handler that serves files from `src/main/resources/static`, and that handler's exception is how
"nothing here" gets reported.

None of these problems has a `type`. Spring leaves it at `about:blank` and omits it when it writes the
JSON, and the RFC says what that means: the problem is exactly what the status code says, and `title` is
the status's own phrase, "Bad Request" or "Not Found". For a body that is not JSON there is nothing more
specific the bookshop could tell a client anyway.

The right-hand column of the table is not guesswork. The `dev` profile from lesson 4 logs Spring's web
classes at `debug`, and among those lines is the exception behind every error answer, which is the first
place to look when an answer surprises you. With the application started with
`--spring.profiles.active=dev`, on port 8081, five of the requests above left these lines in the second terminal. The sixth, with `"cheap"`, was left
out; its answer was the first one's word for word.

```
2026-10-16T20:42:41.715-03:00 DEBUG 16814 --- [bookshop] [nio-8081-exec-1] .m.m.a.ExceptionHandlerExceptionResolver : Resolved [org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error: Unexpected end-of-input within/between Object entries]
2026-10-16T20:42:41.746-03:00 DEBUG 16814 --- [bookshop] [nio-8081-exec-2] .m.m.a.ExceptionHandlerExceptionResolver : Resolved [org.springframework.web.method.annotation.MethodArgumentTypeMismatchException: Method parameter 'id': Failed to convert value of type 'java.lang.String' to required type 'long'; For input string: "abc"]
2026-10-16T20:42:41.792-03:00 DEBUG 16814 --- [bookshop] [nio-8081-exec-3] .m.m.a.ExceptionHandlerExceptionResolver : Resolved [org.springframework.web.servlet.resource.NoResourceFoundException: No static resource nope for request '/nope'.]
2026-10-16T20:42:41.818-03:00 DEBUG 16814 --- [bookshop] [nio-8081-exec-4] .m.m.a.ExceptionHandlerExceptionResolver : Resolved [org.springframework.web.HttpRequestMethodNotSupportedException: Request method 'DELETE' is not supported]
2026-10-16T20:42:41.874-03:00 DEBUG 16814 --- [bookshop] [nio-8081-exec-5] .m.m.a.ExceptionHandlerExceptionResolver : Resolved [org.springframework.web.HttpMediaTypeNotSupportedException: Content-Type 'text/plain;charset=UTF-8' is not supported]
```

Each line names the exception and its own message, which often says more than the response did. The
first says it most clearly: the client was told "Failed to read request", and the log has Jackson's
`JSON parse error: Unexpected end-of-input within/between Object entries`. The difference is deliberate,
and the last section of this lesson is about it.

So an exception now meets three layers on its way out, and the first that claims it answers:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Three stacked bands that an exception falls through from top to bottom. First, the bookshop&#x27;s own handlers: BookNotFoundException gives 404 and DuplicateIsbnException gives 409. Second, the handlers inherited from ResponseEntityExceptionHandler: HttpMessageNotReadableException 400, MethodArgumentTypeMismatchException 400, NoResourceFoundException 404, HttpRequestMethodNotSupportedException 405, HttpMediaTypeNotSupportedException 415, and MethodArgumentNotValidException 400, which the bookshop overrides. Third, Spring Boot&#x27;s error page, which answers anything else with 500 and its own shape: timestamp, status, error, path.\"><defs><marker id=\"lyr-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"80\" y=\"20\" width=\"600\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"96\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the bookshop's handlers</text><text x=\"330\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BookNotFoundException</text><text x=\"578\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 404</text><text x=\"330\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DuplicateIsbnException</text><text x=\"578\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 409</text><rect x=\"80\" y=\"100\" width=\"600\" height=\"128\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"96\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">inherited from</text><text x=\"96\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ResponseEntityExceptionHandler</text><text x=\"330\" y=\"119.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HttpMessageNotReadableException</text><text x=\"578\" y=\"119.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 400</text><text x=\"330\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MethodArgumentTypeMismatchException</text><text x=\"578\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 400</text><text x=\"330\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NoResourceFoundException</text><text x=\"578\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 404</text><text x=\"330\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HttpRequestMethodNotSupportedException</text><text x=\"578\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 405</text><text x=\"330\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HttpMediaTypeNotSupportedException</text><text x=\"578\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 415</text><text x=\"330\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MethodArgumentNotValidException</text><text x=\"578\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 400</text><text x=\"616\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(overridden)</text><rect x=\"80\" y=\"244\" width=\"600\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"96\" y=\"276.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spring Boot's error page</text><text x=\"330\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">anything else</text><text x=\"330\" y=\"285.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 500, timestamp, status, error, path</text><line x1=\"40\" y1=\"24\" x2=\"40\" y2=\"300\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#lyr-a)\"></line><text x=\"30\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" transform=\"rotate(-90 30 160)\">an exception</text></svg>", "caption": "The first two layers answer in the problem shape. Whatever falls through both reaches Spring Boot, which answers 500 in a shape of its own."}
```
