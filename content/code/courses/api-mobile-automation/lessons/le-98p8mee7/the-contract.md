---
title: The contract, written down
version: 1
---

**A contract is the API's promise to its clients, written where both sides can read it: which
addresses exist, what each one accepts, and every answer it may give.** Without one, the only
statement of what boxoffice does is boxoffice itself, and a test can then only check that the
server does what the server does. That test passes forever and finds nothing.

The common belief is that the code is the truth and the document is a description of it, drafted
afterwards and allowed to lag. A tester takes the opposite view. **The contract is what was
promised, and where the code disagrees with it, one of the two is wrong.** Sometimes it is the
document. Either way the disagreement is a finding, and section 06 finds three.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 214\" role=\"img\" aria-label=\"Three boxes in a row: the consumer, an app or a test, on the left; the contract, openapi.yaml, in the middle; the provider, boxoffice, on the right. An arrow from the consumer to the contract says built against; an arrow from the provider to the contract says checked against. Underneath, a line runs from the consumer to the provider: a request and its answer, at run time.\"><defs><marker id=\"f02contract-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"160\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consumer</text><text x=\"100\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">an app, a test</text><rect x=\"270\" y=\"80\" width=\"160\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the contract</text><text x=\"350\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">openapi.yaml</text><rect x=\"520\" y=\"80\" width=\"160\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">provider</text><text x=\"600\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice</text><line x1=\"182\" y1=\"108\" x2=\"268\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f02contract-ah)\"></line><text x=\"225\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">built against</text><line x1=\"518\" y1=\"108\" x2=\"432\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f02contract-ah)\"></line><text x=\"475\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">checked against</text><line x1=\"100\" y1=\"138\" x2=\"100\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"100\" y1=\"190\" x2=\"600\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"600\" y1=\"190\" x2=\"600\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f02contract-ah)\"></line><text x=\"350\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a request and its answer, at run time</text><text x=\"350\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each side depends on the document, never on the other side’s code</text></svg>", "caption": "The consumer is built against the contract and the provider is checked against it; at run time only requests and answers pass between them."}
```

Two kinds of program depend on the contract and never on each other's code. The **consumer** is
anything that calls the API: an app, a website, a test. The **provider** is the server that answers.
The consumer is built against the document, the provider is checked against it, and when both hold
to it they work together without either team reading the other's source.

## OpenAPI

The usual language for an HTTP contract is OpenAPI, a document in YAML or JSON. This one is written
in version 3.1, which the tools in this course understand: Postman imports it, lesson 10 checks
responses against schemas like the ones inside it, and the mock server of lesson 11 runs from it
directly. Here is boxoffice's. Copy it with the button on its block, then open your editor in the
project directory, paste it and save it as `openapi.yaml`:

```yaml
openapi: 3.1.0
info:
  title: boxoffice
  version: 1.0.0
  description: The ticket API of a small theatre in São Paulo.
servers:
  - url: http://localhost:8080

paths:
  /health:
    get:
      summary: Whether the server is up
      security: []
      responses:
        '200':
          description: It is.
          content:
            application/json:
              schema:
                type: object
                required: [status]
                properties:
                  status: { const: ok }

  /v1/shows:
    get:
      summary: The shows, optionally on one day
      security: []
      parameters:
        - name: date
          in: query
          required: false
          description: Only the shows starting on this day, in São Paulo time.
          schema: { type: string, format: date }
      responses:
        '200':
          description: The shows, in date order. An empty list when none matches.
          headers:
            cache-control:
              schema: { type: string, example: max-age=60 }
          content:
            application/json:
              schema:
                type: object
                required: [shows]
                properties:
                  shows:
                    type: array
                    items: { $ref: '#/components/schemas/Show' }
        '400': { $ref: '#/components/responses/Problem' }

  /v1/shows/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema: { type: string, example: sh-103 }
    get:
      summary: One show, with the seats it has left
      security: []
      parameters:
        - name: if-none-match
          in: header
          required: false
          description: The etag of a copy the client holds.
          schema: { type: string }
      responses:
        '200':
          description: The show.
          headers:
            etag:
              description: A fingerprint of this version of the show.
              schema: { type: string }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Show' }
        '304':
          description: The copy the client holds is still current. No body.
        '404': { $ref: '#/components/responses/Problem' }

  /oauth/token:
    post:
      summary: A token for a program, by the client credentials grant
      security: []
      requestBody:
        required: true
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              required: [grant_type, client_id, client_secret]
              properties:
                grant_type: { const: client_credentials }
                client_id: { type: string }
                client_secret: { type: string }
      responses:
        '200':
          description: A token.
          headers:
            cache-control:
              schema: { const: no-store }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Token' }
        '400': { $ref: '#/components/responses/OAuthError' }
        '401': { $ref: '#/components/responses/OAuthError' }

  /v1/orders:
    post:
      summary: Buy seats for a show
      security:
        - oauth: ['orders:write']
      parameters:
        - name: Idempotency-Key
          in: header
          required: false
          description: Sending the same key again replays the first answer.
          schema: { type: string }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/NewOrder' }
      responses:
        '201':
          description: The order, confirmed and paid.
          headers:
            location:
              description: Where the order lives.
              schema: { type: string, example: /v1/orders/ord-1001 }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Order' }
        '400': { $ref: '#/components/responses/Problem' }
        '401': { $ref: '#/components/responses/Problem' }
        '402': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
        '409': { $ref: '#/components/responses/Problem' }
        '415': { $ref: '#/components/responses/Problem' }
        '422': { $ref: '#/components/responses/Problem' }
        '502': { $ref: '#/components/responses/Problem' }
        '504': { $ref: '#/components/responses/Problem' }

  /v1/orders/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema: { type: string, example: ord-1001 }
    get:
      summary: One of your own orders
      security:
        - oauth: ['orders:read']
      responses:
        '200':
          description: The order.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Order' }
        '401': { $ref: '#/components/responses/Problem' }
        '404': { $ref: '#/components/responses/Problem' }
    delete:
      summary: Cancel one of your own orders
      security:
        - oauth: ['orders:write']
      responses:
        '204':
          description: Cancelled, or it already was.
        '401': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
        '404': { $ref: '#/components/responses/Problem' }

  /v1/reports/sales:
    get:
      summary: What has been sold, for the theatre's staff
      security:
        - staffKey: []
      responses:
        '200':
          description: The totals. They lag a moment behind the orders.
          content:
            application/json:
              schema:
                type: object
                required: [orders, seats, revenue_cents]
                properties:
                  orders: { type: integer, minimum: 0 }
                  seats: { type: integer, minimum: 0 }
                  revenue_cents: { type: integer, minimum: 0 }
        '401': { $ref: '#/components/responses/Problem' }

components:
  schemas:
    Show:
      type: object
      required: [id, title, starts_at, price_cents, seats_left]
      properties:
        id: { type: string, example: sh-103 }
        title: { type: string }
        starts_at: { type: string, format: date-time, example: '2026-11-08T18:00:00-03:00' }
        price_cents: { type: integer, minimum: 0, description: 'The price of one seat, in centavos.' }
        seats_left: { type: integer, minimum: 0 }

    NewOrder:
      type: object
      required: [show_id, seats]
      additionalProperties: false
      properties:
        show_id: { type: string, example: sh-103 }
        seats: { type: integer, minimum: 1, maximum: 6 }

    Order:
      type: object
      required: [id, show_id, seats, total_cents, status]
      properties:
        id: { type: string, example: ord-1001 }
        show_id: { type: string }
        seats: { type: integer, minimum: 1, maximum: 6 }
        total_cents: { type: integer, minimum: 0 }
        status: { enum: [confirmed, declined, failed, cancelled] }
        payment: { type: string, description: 'The charge, once one was approved.' }

    Token:
      type: object
      required: [access_token, token_type, expires_in, scope]
      properties:
        access_token: { type: string }
        token_type: { const: Bearer }
        expires_in: { type: integer, description: Seconds the token lives. }
        scope: { type: string, example: 'orders:read orders:write' }

    Problem:
      type: object
      required: [type, title, status, detail]
      properties:
        type: { type: string, format: uri-reference, example: about:blank }
        title: { type: string }
        status: { type: integer }
        detail: { type: string }

  responses:
    Problem:
      description: Something went wrong, said in RFC 9457's shape.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
    OAuthError:
      description: The token was refused, in OAuth's own error shape.
      content:
        application/json:
          schema:
            type: object
            required: [error]
            properties:
              error: { enum: [unsupported_grant_type, invalid_client] }

  securitySchemes:
    oauth:
      type: oauth2
      flows:
        clientCredentials:
          tokenUrl: /oauth/token
          scopes:
            'orders:read': read your own orders
            'orders:write': create and cancel orders
    staffKey:
      type: apiKey
      in: header
      name: X-Api-Key
```

YAML marks structure with indentation: two spaces deeper means *inside*. `{ type: string }` and
`[show_id, seats]` are the same structures written on one line, an object and a list. A tab
character breaks YAML, which is a good reason to copy the file rather than retype it.

## How to read it

The file has four parts. `info` and `servers` say what it describes and where; `paths` lists every
address and what each method does there; `components` holds the pieces several paths share, which a
path points at with `$ref`. Most of the reading happens under `paths`, and the operation that buys
seats has every kind of entry in it:

```schooling-example
{"language": "yaml", "parts": [{"code": "  /v1/orders:\n    post:\n      summary: Buy seats for a show", "note": "A path, and under it one entry per method it accepts. `/v1/orders` accepts only `post`, so anything else there is outside the contract."}, {"code": "      security:\n        - oauth: ['orders:write']", "note": "Who may call it: a token from the `oauth` scheme carrying the scope `orders:write`. The scheme is defined at the foot of the file, and lesson 3 tests it."}, {"code": "      parameters:\n        - name: Idempotency-Key\n          in: header\n          required: false\n          description: Sending the same key again replays the first answer.\n          schema: { type: string }", "note": "An optional header. `in` says where a parameter travels: `path`, `query` or `header`. What the key does is lesson 13."}, {"code": "      requestBody:\n        required: true\n        content:\n          application/json:\n            schema: { $ref: '#/components/schemas/NewOrder' }", "note": "The body is required and must be JSON. Its shape lives in `components` under the name `NewOrder`, and `$ref` points there instead of repeating it."}, {"code": "      responses:\n        '201':\n          description: The order, confirmed and paid.\n          headers:\n            location:\n              description: Where the order lives.\n              schema: { type: string, example: /v1/orders/ord-1001 }\n          content:\n            application/json:\n              schema: { $ref: '#/components/schemas/Order' }", "note": "Responses are keyed by status code, in quotes because YAML would otherwise read them as numbers. The `201` promises a `location` header and an `Order` in the body."}, {"code": "        '400': { $ref: '#/components/responses/Problem' }\n        '401': { $ref: '#/components/responses/Problem' }\n        '402': { $ref: '#/components/responses/Problem' }\n        '403': { $ref: '#/components/responses/Problem' }\n        '409': { $ref: '#/components/responses/Problem' }\n        '415': { $ref: '#/components/responses/Problem' }\n        '422': { $ref: '#/components/responses/Problem' }\n        '502': { $ref: '#/components/responses/Problem' }\n        '504': { $ref: '#/components/responses/Problem' }", "note": "Every error this operation may give, and all of them share one shape. That list is a promise too: a code missing from it, such as `500`, is a code the client was told it would never see. Section 05 reads the shape."}, {"code": "    NewOrder:\n      type: object\n      required: [show_id, seats]\n      additionalProperties: false\n      properties:\n        show_id: { type: string, example: sh-103 }\n        seats: { type: integer, minimum: 1, maximum: 6 }", "note": "The body's rules, further down the file in `components`. Both fields are required; no other field is allowed; `seats` is an integer from 1 to 6. Each of those clauses becomes test cases in section 06."}]}
```

Reading a contract is answering one question per request: **for this input, which answers are
allowed?** For `POST /v1/orders` the file says a body with `show_id` and between 1 and 6 seats, and
nothing else, can be answered with a `201` and a `location`; every other answer is one of nine error
codes, all in the same shape. A response outside that list, a `500` for instance, breaks the contract whatever its body
says.

## Checking one promise by hand

The schema `Show` requires five fields. A show from the live server should have exactly those, and
jq's `keys` lists a response's fields in alphabetical order:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq -c keys
["id","price_cents","seats_left","starts_at","title"]
```

Five, the same five. This is a contract check, done by eye, and it is the whole idea behind lesson
10, which does it with a validator against every response at once.

## What it does not say

A contract is small on purpose, and leaving something out is a choice. This one does not list the
`405` every path gives to a method it does not accept, which lesson 1 covered. It does not describe
the `www-authenticate` header that comes with a `401`, which is lesson 3, or what a repeated
`Idempotency-Key` does, which is lesson 13. Each of those lessons is a place where a fuller contract
would grow a line, and the line would be the next thing to test.
