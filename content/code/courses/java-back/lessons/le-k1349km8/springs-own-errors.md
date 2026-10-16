---
title: Spring's own errors, in the same shape
version: 1
---

Some errors happen before any code of the bookshop runs: the body is not JSON, the path matches no
controller, the method is one the path does not take. Spring MVC raises exceptions of its own for these,
and lesson 6's bookshop answered them with Spring Boot's error page, in its own shape:

@@CAP before-spring@@

Two shapes in one API is worse than either of them alone. A client that reads `type` and `detail` from
one 400 and finds `timestamp` and `error` in the next has to handle both, and nothing tells it which to
expect.

**`ResponseEntityExceptionHandler`** is the fix, and it is why `ApiErrorHandler` extends it. The class is
Spring's. It carries an `@ExceptionHandler` for the exceptions Spring MVC raises itself, and each one
answers with a `ProblemDetail`. Extending it puts all of them inside the bookshop's advice, beside the
bookshop's own handlers. Ask the rebuilt bookshop the same kinds of thing, and a few more:

@@CAP spring@@

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
place to look when an answer surprises you. Started with `--spring.profiles.active=dev`, on port 8081,
the first five requests above left these lines in the second terminal:

@@CAP resolved@@

@@RESOLVED-NOTE@@

So an exception now meets three layers on its way out, and the first that claims it answers:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Three stacked bands that an exception falls through from top to bottom. First, the bookshop&#x27;s own handlers: BookNotFoundException gives 404 and DuplicateIsbnException gives 409. Second, the handlers inherited from ResponseEntityExceptionHandler: HttpMessageNotReadableException 400, MethodArgumentTypeMismatchException 400, NoResourceFoundException 404, HttpRequestMethodNotSupportedException 405, HttpMediaTypeNotSupportedException 415, and MethodArgumentNotValidException 400, which the bookshop overrides. Third, Spring Boot&#x27;s error page, which answers anything else with 500 and its own shape: timestamp, status, error, path.\"><defs><marker id=\"lyr-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"80\" y=\"20\" width=\"600\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"96\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the bookshop's handlers</text><text x=\"330\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BookNotFoundException</text><text x=\"578\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 404</text><text x=\"330\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DuplicateIsbnException</text><text x=\"578\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 409</text><rect x=\"80\" y=\"100\" width=\"600\" height=\"128\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"96\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">inherited from</text><text x=\"96\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ResponseEntityExceptionHandler</text><text x=\"330\" y=\"119.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HttpMessageNotReadableException</text><text x=\"578\" y=\"119.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 400</text><text x=\"330\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MethodArgumentTypeMismatchException</text><text x=\"578\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 400</text><text x=\"330\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NoResourceFoundException</text><text x=\"578\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 404</text><text x=\"330\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HttpRequestMethodNotSupportedException</text><text x=\"578\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 405</text><text x=\"330\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HttpMediaTypeNotSupportedException</text><text x=\"578\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 415</text><text x=\"330\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MethodArgumentNotValidException</text><text x=\"578\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 400</text><text x=\"616\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(overridden)</text><rect x=\"80\" y=\"244\" width=\"600\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"96\" y=\"276.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spring Boot's error page</text><text x=\"330\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">anything else</text><text x=\"330\" y=\"285.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 500, timestamp, status, error, path</text><line x1=\"40\" y1=\"24\" x2=\"40\" y2=\"300\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#lyr-a)\"></line><text x=\"30\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" transform=\"rotate(-90 30 160)\">an exception</text></svg>", "caption": "The first two layers answer in the problem shape. Whatever falls through both reaches Spring Boot, which answers 500 in a shape of its own."}
```
