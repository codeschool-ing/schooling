---
title: Swagger UI, and what production should not serve
version: 1
---

A document of four hundred lines is what a program wants. A person wants to see the operations,
open one, and send it. **Swagger UI** is a web page that does that with any OpenAPI document, and
the `-ui` starter put a copy of it inside the bookshop's jar.

```
ana@vm:~/bookshop$ curl -si localhost:8080/swagger-ui.html | head -3
HTTP/1.1 302 
X-Request-Id: c06bb7b1
Location: /swagger-ui/index.html
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/swagger-ui/index.html
200
```

`/swagger-ui.html` is a short address that redirects, with a 302, to the page itself. The page is
static: HTML and JavaScript that ask the server for a small configuration, and through it for the
document you have been reading.

```
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/v3/api-docs/swagger-config
{"configUrl":"/v3/api-docs/swagger-config","oauth2RedirectUrl":"http://localhost:8080/swagger-ui/oauth2-redirect.html","url":"/v3/api-docs","validatorUrl":""}
```

`"url":"/v3/api-docs"` is the document Swagger UI draws. It draws nothing from the controllers; it
knows only what the document says, which is why the previous two sections mattered.

## Reading the page

Open `http://localhost:8080/swagger-ui.html` in a browser on the machine where the bookshop runs.
At the top are the title, version and description from `OpenApiConfig`, and a button labelled
**Authorize**. Below them the operations come grouped by tag: **Catalogue** with its five operations, in the words
you wrote in `@Tag` and `@Operation`, and `order-controller` and `token-controller`, named by
springdoc after their classes. Each operation opens to its parameters, its request
body with an example built from the schema, and the responses it declared. `POST /books` carries a
padlock, because of its `security` entry; the orders carry none, although they need a token as
much, because nothing told springdoc. At the bottom are the schemas, `ProblemDetail` among them.

## Sending a request from it

Every operation has a **Try it out** button, which turns the fields into a form, and **Execute**,
which sends the request from your browser to the bookshop and shows what came back, with a `curl`
command that sends the same request. The reading operations work as they are.

Adding a book needs a token with `catalogue:write`, which the clerk has. Get one in the terminal
the way lesson 15 did:

```
ana@vm:~/bookshop$ curl -s -u clerk:clerk-adds-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > clerk.token
```

Press **Authorize**, paste the contents of `clerk.token` into the field for `bearer`, and close the
dialog. Swagger UI now sends `Authorization: Bearer` and the token with every operation that
declares the scheme. Open `POST /books`, press **Try it out**, edit the example into a real book
and **Execute**. It sends the same request as the first command below, and gets the same answer.
The second command is that request again with no token:

```
ana@vm:~/bookshop$ curl -s -w '\n%{http_code}\n' -H "Authorization: Bearer $(cat clerk.token)" -H 'Content-Type: application/json' -d '{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}' localhost:8080/books
{"id":7,"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}
201
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -d '{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}' localhost:8080/books
401
```

This is not a second door into the bookshop. Swagger UI is a client like `curl`, running in your
browser, and the bookshop checks its requests exactly as it checks `curl`'s: without a token,
`POST /books` gets a 401 whichever client sends it.

## In production

The second terminal has been printing two warnings at every start since springdoc arrived:

```
2026-10-22T20:23:06.219-03:00  WARN 20356 --- [bookshop] [           main] [] o.s.core.events.SpringDocAppInitializer  : SpringDoc /v3/api-docs endpoint is enabled by default. To disable it in production, set the property 'springdoc.api-docs.enabled=false'
2026-10-22T20:23:06.220-03:00  WARN 20356 --- [bookshop] [           main] [] o.s.core.events.SpringDocAppInitializer  : SpringDoc /swagger-ui.html endpoint is enabled by default. To disable it in production, set the property 'springdoc.swagger-ui.enabled=false'
```

springdoc is telling you that its defaults are for development. In production, a full description
of every endpoint and a form for calling them are a gift to anybody looking for a way in: they do
not open a single lock, since every operation still checks its token, but they save the visitor
the work of finding the doors. Some APIs are public and publish their document on purpose. An API
like the bookshop's, called by its own web page, has no reason to.

The property in the first warning is enough. Stop the application in the second terminal and start it with the
property on the command line:

```sh
java -jar target/bookshop-0.1.0.jar --springdoc.api-docs.enabled=false
```

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs
404
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/swagger-ui.html
404
```

Both paths are 404, the page as well as the document, because Swagger UI has nothing to draw
without one. The warnings are gone from the second terminal, too. The property is ordinary Spring
configuration, so it goes wherever the rest of a deployment's configuration goes: a line in the
properties file of a production profile, as lesson 4 set up `dev`, or an environment variable,
whose name is the property in capitals with the dots turned into underscores and the dash removed:

```sh
SPRINGDOC_APIDOCS_ENABLED=false java -jar target/bookshop-0.1.0.jar
```

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs
404
```

The bookshop keeps the document on by default because you are still developing it; lesson 23
starts the application with its configuration in the environment, where this variable belongs.
