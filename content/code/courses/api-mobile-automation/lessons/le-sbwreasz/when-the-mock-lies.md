---
title: When the mock lies, and how to catch it
version: 1
---

**A stand-in is a claim about another program, written by somebody who was not that program.** It is
true on the day it is written, if the person read the provider's documentation carefully, and it
stays exactly as it was while the provider moves on. The failure that follows is the worst kind a
test suite has: everything is green, and production is broken.

## A mock that answers 200

Imagine the WireMock mapping had been written from memory, by somebody who assumed that a payment
provider answers `200 OK` to a charge. WireMock can take a mapping over its admin API as well as
from a file, which is how a test sets up a stand-in for one case. So the wrong one can be added
while it runs. Priority 1 puts it ahead of both files:

```
ana@laptop:~/boxoffice$ curl -s localhost:8091/__admin/mappings -d '{"priority":1,"request":{"method":"POST","url":"/charges"},"response":{"status":200,"jsonBody":{"id":"ch-wm-3","status":"approved"}}}' | jq -c '{id, response}'
{"id":"35ad87b9-38e9-4d60-ad17-3c2157422d5e","response":{"status":200,"jsonBody":{"id":"ch-wm-3","status":"approved"}}}
```

Then an ordinary order through boxoffice, which is still pointed at WireMock:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}'
{"type":"about:blank","title":"Bad Gateway","status":502,"detail":"the payment provider failed"}
```

`502`, *the payment provider failed*. boxoffice's own log says why:

```
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8091 node boxoffice.mjs
boxoffice listening on http://localhost:8080
POST /v1/orders 201
POST /v1/orders 402
POST /v1/orders 201
GET /v1/shows?date=tomorrow 200
  payments: payments answered 200
POST /v1/orders 502
```

`payments answered 200`: boxoffice accepts only `201`, so it treated the charge as failed and
refused the order. **Here boxoffice is right and the mock is wrong**, and the test went red, which
is the lucky case. Turn it around and it stops being lucky. Had boxoffice been written against this
mock, by a developer who checked for `200`, every test would pass. In production, every order would
fail against a provider that answers `201`. The suite would have tested boxoffice against a provider
that does not exist.

So when a test against a stand-in fails, there are always two suspects, and **the question "who is
right?" cannot be answered by either program**. It is answered by what the provider promises.

## The provider's contract

A provider publishes what it accepts and answers, more and more often as an OpenAPI document like
boxoffice's own. The provider in this course is imaginary, so its contract is written here, kept to
the one operation boxoffice uses. Save it as `payments.yaml`:

```yaml
openapi: 3.1.0
info:
  title: payments
  version: 1.0.0
  description: The charges endpoint of the payment provider, as the provider publishes it.
paths:
  /charges:
    post:
      summary: Charge an amount, once per idempotency key
      parameters:
        - name: idempotency-key
          in: header
          required: true
          schema: { type: string }
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [amount_cents, reference]
              properties:
                amount_cents: { type: integer, minimum: 1 }
                reference: { type: string }
      responses:
        '201':
          description: The charge, approved or declined.
          content:
            application/json:
              schema:
                type: object
                required: [id, status]
                properties:
                  id: { type: string }
                  status: { enum: [approved, declined] }
```

It says three things a stand-in has to honour: the `idempotency-key` header is required, a charge is
answered with `201`, and `status` is `approved` or `declined` and nothing else.

## Prism as a referee

Section 05 used Prism to answer from a contract. It has a second mode, `proxy`, in which **it
answers nothing itself**. It forwards every request to a real server, then checks the request and
the answer against the contract on the way through. With `--errors`, a violation in either direction
becomes an error answer instead of a line in Prism's log. Stop the Prism mock with Ctrl-C if it is
still running, and start the referee in its place, in front of WireMock:

```sh
npx --yes @stoplight/prism-cli@5.14.2 proxy payments.yaml http://localhost:8091 --errors
```

A charge through the proxy, with the lying mapping still in WireMock:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/charges -H 'content-type: application/json' -H 'idempotency-key: try-1' -d '{"amount_cents":16000,"reference":"ord-9001"}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 500 Internal Server Error
sl-violations: [{"location":["response"],"severity":"Error","message":"Unable to match the returned status code with those defined in the document: 201"}]
```

**The lie, caught, by the provider's own document.** Prism replaced WireMock's answer with a `500`
and said why: the contract defines `201` for this operation, and the stand-in answered something
else. Reset WireMock, which drops the mapping added over the API and reads the files again, and
send the same charge with a new key:

```
ana@laptop:~/boxoffice$ curl -s -X POST localhost:8091/__admin/mappings/reset
ana@laptop:~/boxoffice$ curl -si localhost:4010/charges -H 'content-type: application/json' -H 'idempotency-key: try-2' -d '{"amount_cents":16000,"reference":"ord-9001"}' | grep -iE '^HTTP|^sl-violations|^\{'
HTTP/1.1 201 Created
{"id":"ch-wm-1","status":"approved"}
```

`201`, an `approved` body, and no `sl-violations`: the two files tell the truth, as far as this
contract can see.

## It checks the caller too

A proxy checks what goes in as well as what comes out. The same charge without the
`idempotency-key` header:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/charges -H 'content-type: application/json' -d '{"amount_cents":16000,"reference":"ord-9001"}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 422 Unprocessable Entity
```

The contract requires the header, so this request would be a defect in whoever sent it. boxoffice
always sends one, but **a client that forgot it would be caught here** rather than by a provider that
might, or might not, refuse it.

## Keeping a stand-in honest

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 262\" role=\"img\" aria-label=\"boxoffice sends a charge to a Prism proxy started with --errors, which forwards it to a stand-in, WireMock or the stub. Above the proxy sits the contract, payments.yaml, and the proxy checks the request and the answer against it. On the right, the real provider is checked against the same contract by contract tests, lesson 10. A stand-in stays honest while both checks pass.\"><defs><marker id=\"f11referee-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"230\" y=\"20\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the contract</text><text x=\"315\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payments.yaml</text><rect x=\"560\" y=\"20\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the provider</text><text x=\"625\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the real one</text><rect x=\"20\" y=\"170\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><rect x=\"230\" y=\"170\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Prism proxy</text><text x=\"315\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--errors</text><rect x=\"560\" y=\"170\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a stand-in</text><text x=\"625\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">WireMock, the stub</text><line x1=\"152\" y1=\"195\" x2=\"228\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11referee-ah)\"></line><text x=\"190\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a charge</text><line x1=\"402\" y1=\"195\" x2=\"558\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11referee-ah)\"></line><text x=\"480\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">forwarded</text><line x1=\"315\" y1=\"72\" x2=\"315\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11referee-ah)\"></line><text x=\"325\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">checks the request</text><text x=\"325\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">and the answer</text><line x1=\"558\" y1=\"45\" x2=\"402\" y2=\"45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11referee-ah)\"></line><text x=\"480\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">contract tests</text><text x=\"480\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lesson 10</text><text x=\"355\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a stand-in stays honest while both checks pass</text></svg>", "caption": "Two checks meet at the provider’s contract: the stand-in through the proxy, and the provider through contract tests."}
```

Two checks meet at the contract, and a stand-in is honest only while both pass. The first is the
stand-in against the contract. Run boxoffice's tests with `PAYMENTS_URL` pointing at a Prism proxy
in front of the stand-in, and every charge any test makes is checked on the way. A mapping that
drifted then fails the run that uses it. The second is the provider against the contract, because
the contract is only a claim too until somebody checks the real provider against it. That is the
contract testing of lesson 10, and it is the provider's job as much as yours; ask whether they do
it.

Two habits do the rest. **Build stand-ins from the provider's documentation and its contract**,
never from memory or from what your own code happens to expect. A stand-in written from your code
agrees with your code by construction. And when the provider announces a change, change the contract
first and let the referee tell you which stand-ins are now lying.

A contract has holes of its own. This one lists no `500`, though real providers do answer one now
and then, and the stub of section 03 answers it on purpose in `down` mode. This proxy reports
any status the contract does not list, as it reported the `200`. Whether that is the stand-in's
fault or the contract's is a question for the provider, and asking it is part of the job.
