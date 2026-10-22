---
title: Swagger UI, and what production should not serve
version: 1
---

A document of four hundred lines is what a program wants. A person wants to see the operations,
open one, and send it. **Swagger UI** is a web page that does that with any OpenAPI document, and
the `-ui` starter put a copy of it inside the bookshop's jar.

```
(pending REDIRECT)
```

`/swagger-ui.html` is a short address that redirects, with a 302, to the page itself. The page is
static: HTML and JavaScript that ask the server for a small configuration, and through it for the
document you have been reading.

```
(pending CONFIG)
```

`"url":"/v3/api-docs"` is the document Swagger UI draws. It draws nothing from the controllers; it
knows only what the document says, which is why the previous two sections mattered.

## Reading the page

Open `http://localhost:8080/swagger-ui.html` in a browser on the machine where the bookshop runs.
At the top are the title, version and description from `OpenApiConfig`, and a button labelled
**Authorize**. Below them the operations come grouped by tag: **Catalogue** with its five, in the
words you wrote in `@Tag` and `@Operation`, then `order-controller` and `token-controller` with the
names springdoc made up from the class names. Each operation opens to its parameters, its request
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
(pending TOKEN)
```

Press **Authorize**, paste the contents of `clerk.token` into the field for `bearer`, and close the
dialog. Swagger UI now sends `Authorization: Bearer` and the token with every operation that
declares the scheme. Open `POST /books`, press **Try it out**, edit the example into a real book
and **Execute**. The request it sends is this one, and the answer is the same:

```
(pending POST)
```

This is not a second door into the bookshop. Swagger UI is a client like `curl`, running in your
browser, and the bookshop checks its requests in exactly the same way. Without a token, `POST /books`
from the page gets the 401 it gets from anywhere else.

## In production

The second terminal has been printing two warnings at every start since springdoc arrived:

```
(pending WARNINGS)
```

springdoc is telling you that its defaults are for development. In production, a full description
of every endpoint and a form for calling them are a gift to anybody looking for a way in: they do
not open a single lock, since every operation still checks its token, but they save the visitor
the work of finding the doors. Some APIs are public and publish their document on purpose. An API
like the bookshop's, called by its own web page, has no reason to.

The one property is enough, as you can see by starting the application with it:

```
(pending DISABLED)
```

Both paths are 404, the page as well as the document, because Swagger UI has nothing to draw
without one. The warnings are gone from the second terminal, too. The property is ordinary Spring
configuration, so it goes wherever the rest of a deployment's configuration goes: a line in the
properties file of a production profile, as lesson 4 set up `dev`, or an environment variable,
whose name is the property in capitals with the dots turned into underscores and the dash removed:

```
(pending ENV)
```

The bookshop keeps the document on by default because you are still developing it; lesson 23
starts the application with its configuration in the environment, where this variable belongs.
