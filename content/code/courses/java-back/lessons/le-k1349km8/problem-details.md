---
title: Problem details, one shape for every error
version: 1
---

An error response has two readers. A person reads it once, while debugging. A program reads it every
time, to decide what to do next: put a message beside a form field, ask for another ISBN, try again
later. The program needs every error in the same shape, with one field it can compare that does not
change when somebody rewords a sentence. **RFC 9457, "Problem Details for HTTP APIs"**, is that shape.
It replaced RFC 7807 in 2023 and changed little, which is why both numbers still turn up in
documentation.

A problem document is a JSON object sent with the media type **`application/problem+json`**. The RFC
defines five members, every one of them optional:

| member | what it holds |
|---|---|
| `type` | a URI naming the kind of problem, and the member a program compares. Absent, it means `about:blank`: no kind beyond the status code itself |
| `title` | a short summary of the kind, the same every time that kind occurs |
| `status` | the HTTP status code, repeated in the body |
| `detail` | an explanation of this occurrence, written for a person |
| `instance` | a URI for this occurrence |

A problem may carry members of its own as well, which the RFC calls extensions. The bookshop adds one
for validation errors, two sections on.

The common mistake is a client that reads `detail`. "No book has id 99" is written for a person, and on
the day it is reworded to "Book 99 does not exist", every client that matched the words breaks with no
error anywhere. **`type` is the contract.** It is a URI because a URI is a name nobody else picks by
accident, and it does not have to resolve, although a page at that address explaining the problem is a
kindness to whoever reads it.

## One class for every controller

Spring's class for the document is **`ProblemDetail`**, and a handler that returns one has it written as
`application/problem+json`. What picks the handler is `@ExceptionHandler`: a method carrying it answers
the exceptions it names. Written inside a controller, it answers that controller's exceptions and no
others. Written in a class annotated **`@RestControllerAdvice`**, it answers them for every controller in
the application, which is what "global" means in this lesson's title.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 340\" role=\"img\" aria-label=\"A sequence diagram with five lifelines: client, DispatcherServlet, BookController, BookService and ApiErrorHandler. The client sends GET /books/99; the DispatcherServlet calls BookController.get, which calls BookService.get. The service throws BookNotFoundException, which passes back through the controller to the DispatcherServlet. The DispatcherServlet finds the handler for it and calls ApiErrorHandler.notFound, which returns a ProblemDetail with status 404, and the client receives 404 with application/problem+json.\"><defs><marker id=\"flw-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"flw-x\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><line x1=\"70\" y1=\"50\" x2=\"70\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"30.0\" y=\"18\" width=\"80\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><line x1=\"225\" y1=\"50\" x2=\"225\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"163.0\" y=\"18\" width=\"124\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DispatcherServlet</text><line x1=\"365\" y1=\"50\" x2=\"365\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"313.0\" y=\"18\" width=\"104\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"365\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BookController</text><line x1=\"505\" y1=\"50\" x2=\"505\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"463.0\" y=\"18\" width=\"84\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BookService</text><line x1=\"635\" y1=\"50\" x2=\"635\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"580.0\" y=\"18\" width=\"110\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ApiErrorHandler</text><line x1=\"70\" y1=\"82\" x2=\"222\" y2=\"82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"147.5\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /books/99</text><line x1=\"225\" y1=\"118\" x2=\"362\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"295.0\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">get(99)</text><line x1=\"365\" y1=\"154\" x2=\"502\" y2=\"154\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"435.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">get(99)</text><line x1=\"505\" y1=\"196\" x2=\"228\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#flw-x)\"></line><text x=\"365.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">throws BookNotFoundException</text><text x=\"233\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">finds the handler for it</text><line x1=\"225\" y1=\"250\" x2=\"632\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"430.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">notFound(e)</text><line x1=\"635\" y1=\"284\" x2=\"228\" y2=\"284\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"430.0\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ProblemDetail, 404</text><line x1=\"225\" y1=\"316\" x2=\"73\" y2=\"316\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"147.5\" y=\"307\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">404 problem+json</text></svg>", "caption": "The controller never sees the error as an error: the exception passes through it, and the DispatcherServlet looks for a handler that names it."}
```

Create `src/main/java/com/example/bookshop/web/ApiErrorHandler.java`:

```schooling-example
{"language": "java", "file": "ApiErrorHandler.java", "parts": [{"code": "package com.example.bookshop.web;\n\nimport java.net.URI;\nimport java.util.Map;\nimport java.util.TreeMap;\n\nimport org.springframework.http.HttpHeaders;\nimport org.springframework.http.HttpStatus;\nimport org.springframework.http.HttpStatusCode;\nimport org.springframework.http.ProblemDetail;\nimport org.springframework.http.ResponseEntity;\nimport org.springframework.web.bind.MethodArgumentNotValidException;\nimport org.springframework.web.bind.annotation.ExceptionHandler;\nimport org.springframework.web.bind.annotation.RestControllerAdvice;\nimport org.springframework.web.context.request.WebRequest;\nimport org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;\n\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.DuplicateIsbnException;\n", "note": "`ProblemDetail` is Spring's class for the RFC's document. The two exceptions are imported from `catalogue`: the web layer knows the shop's exceptions, and the shop knows nothing about the web."}, {"code": "@RestControllerAdvice\npublic class ApiErrorHandler extends ResponseEntityExceptionHandler {\n", "note": "`@RestControllerAdvice` makes the class a bean whose handlers apply to every controller, and writes whatever they return as the response body. Extending `ResponseEntityExceptionHandler` brings in Spring's own handlers, which the next section is about."}, {"code": "    @ExceptionHandler(BookNotFoundException.class)\n    public ProblemDetail notFound(BookNotFoundException e) {\n        return problem(HttpStatus.NOT_FOUND, \"book-not-found\", \"Book not found\", e.getMessage());\n    }\n\n    @ExceptionHandler(DuplicateIsbnException.class)\n    public ProblemDetail duplicate(DuplicateIsbnException e) {\n        return problem(HttpStatus.CONFLICT, \"duplicate-isbn\", \"Duplicate ISBN\", e.getMessage());\n    }\n", "note": "One method per exception. `@ExceptionHandler` names the exception a method answers, and the status inside the returned document becomes the status of the response."}, {"code": "    @Override\n    protected ResponseEntity<Object> handleMethodArgumentNotValid(\n            MethodArgumentNotValidException e, HttpHeaders headers, HttpStatusCode status, WebRequest request) {\n        Map<String, String> errors = new TreeMap<>();\n        e.getBindingResult().getFieldErrors()\n                .forEach(f -> errors.put(f.getField(), f.getDefaultMessage()));\n        ProblemDetail body = problem(HttpStatus.BAD_REQUEST, \"invalid-request\", \"Invalid request\",\n                errors.size() + \" field(s) failed validation\");\n        body.setProperty(\"errors\", errors);\n        return ResponseEntity.badRequest().body(body);\n    }\n", "note": "Validation failures, with one entry per field. The section after next reads this method line by line."}, {"code": "    private static ProblemDetail problem(HttpStatus status, String type, String title, String detail) {\n        ProblemDetail body = ProblemDetail.forStatusAndDetail(status, detail);\n        body.setType(URI.create(\"https://bookshop.example/problems/\" + type));\n        body.setTitle(title);\n        return body;\n    }\n}", "note": "Every problem is built here, so the shape cannot drift between handlers. `forStatusAndDetail` sets `status` and `detail`. The `type` is a URI under the shop's own domain, one per kind of problem, and `title` names the kind."}]}
```

Build, restart the application, and ask again for book 99 and for a second Dom Casmurro:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -si localhost:8080/books/99 -w '\n'
HTTP/1.1 404 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:40:59 GMT

{"detail":"No book has id 99","instance":"/books/99","status":404,"title":"Book not found","type":"https://bookshop.example/problems/book-not-found"}
ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "title": "Dom Casmurro", "author": "Machado de Assis", "priceCents": 3990}' -w '\n'
HTTP/1.1 409 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:40:59 GMT

{"detail":"A book with ISBN 9786500000016 is already in the catalogue","instance":"/books","status":409,"title":"Duplicate ISBN","type":"https://bookshop.example/problems/duplicate-isbn"}
```

Read the first answer from the top. The status line says 404 with no reason phrase after it: Tomcat 11
sends none, which HTTP/1.1 allows, since a client acts on the number. `Content-Type:
application/problem+json` is there because the handler returned a `ProblemDetail`. In the body, `type`,
`title` and `detail` are the three the handler set, and `status` came from `forStatusAndDetail`. Nothing
in the bookshop set `instance`: Spring filled it with the request's path, `/books/99`, because the
handler left it empty.

The second answer is a **409**, Conflict, rather than a 400. The request was well formed and every field
in it was valid. What it conflicts with is the state of the catalogue, and the same request with another
ISBN would have succeeded. `apis` lesson 1 goes through the status codes and when each one fits.
