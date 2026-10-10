---
title: Describing errors and security
version: 1
---

**The answers a client is most likely to get wrong are the refusals, and they are the ones a
document most often leaves out.** A successful response is the case everybody writes first. The 404,
the 409 and the 422 are what a client has to branch on, and a document that lists only the 200 tells
its readers that nothing else happens.

## Errors

shelf's document handles them in three layers. Every refusal has the same body, so there is one
`Error` schema. The five refusals differ in meaning, so there are five entries under
`components/responses`, each with its own description. And each operation lists the codes it can
really return, by reference, so `GET /books/{id}` lists 404 and not 409, because reading a book
cannot clash with anything.

What the body of an error should contain is a question of its own. shelf's is one sentence in a
field called `error`, and lesson 2 gives errors a shape a program can read. There is also a standard
shape with a media type of its own, `application/problem+json`. Whatever the shape, the document
says it once under `components` and every operation points at it.

**`default` is the tempting shortcut.** Instead of a code, an operation may list `default`, meaning
"any status not listed here", with the error schema under it:

```yaml
responses:
  "200": {$ref: "#/components/responses/OneBook"}
  default: {$ref: "#/components/responses/AnyError"}
```

It is honest about one thing: a server can always fail in ways nobody listed, a 500 or a 503 from a
proxy in front of it. But it also hides the difference between a refusal somebody designed and one
nobody expected. If `PATCH /books/{id}` crashed tomorrow and answered 500, an operation with a
`default` would have that 500 listed, and a contract test that honours `default` would pass it.
shelf's document has no `default`, and `check_contract.py` looks codes up one by one, so any code
`rest.py` sends that nobody designed comes out as unlisted. If you use `default`, keep it for the
failures you truly cannot name, and still list every code you can.

## Security schemes

shelf asks nobody who they are; lesson 7 is where that starts. But this is where a document would
say how a client proves who it is, and the shape is worth recognising now. It has two parts: a scheme
defined once under `components/securitySchemes`, and a `security` list that says where it
applies, for the whole API at the top level or for one operation:

```yaml
components:
  securitySchemes:
    staffKey:
      type: apiKey
      in: header
      name: X-Api-Key
security:
  - staffKey: []
paths:
  /books:
    get:
      security: []
```

Read it in two steps. The top-level `security` says every operation needs the key named
`staffKey`. Then `GET /books` overrides it with an empty list, which means "no scheme needed", so
the list of books stays public while everything else needs a key. The scheme says only where the key travels, in a
header called `X-Api-Key`. **It never contains a key**, and a real key written into an example in
the document would be published with the documentation page.

The scheme types are few, and all but one are the subject of a lesson in this course:

| `type` | what the client sends | lesson |
|---|---|---|
| `apiKey` | a key in a header, a query string or a cookie | 7 |
| `http` with `scheme: basic` or `scheme: bearer` | an `Authorization` header with a password or a token | 7 and 8 |
| `oauth2`, `openIdConnect` | a token obtained through one of OAuth's flows | 9 |
| `mutualTLS` | a certificate, checked during the TLS handshake | not in this course |

**Describing a scheme enforces nothing.** The document can say that `POST /books` needs a key, and
`rest.py` will go on accepting books from anybody, because the document is read by people and tools,
and `rest.py` never opens it. The two are joined the same way as everything else in this lesson: a contract
test that sends the request with no key and expects 401. Once an API checks keys, which is lesson 7's
subject, that request is one more line in a test like `check_contract.py`, and the 401 is one more
response in the document it checks against.
