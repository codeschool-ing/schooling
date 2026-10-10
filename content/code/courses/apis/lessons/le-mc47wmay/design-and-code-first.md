---
title: Design-first and code-first
version: 1
---

**There are two orders in which a specification and its code can come to exist, and the difference
is which of the two people write.** In **design-first**, people write the document, argue about it
and agree on it, and the code is built to match. In **code-first**, people write the code with a
few annotations, and a framework produces the document from it. Each order makes one thing cheap and
another thing someone's job.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Two ways of working. Design-first: people write openapi.yaml and review it; from it come the server code, the clients, the documentation and a mock server, and a contract test runs between the spec and the server. Code-first: people write the code with annotations; a framework generates openapi.yaml from it, and the documentation and clients come from that.\"><defs><marker id=\"l06-flow-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">design-first</text><rect x=\"20\" y=\"46\" width=\"150\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">openapi.yaml</text><text x=\"95.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">written and reviewed</text><rect x=\"250\" y=\"52\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">server code</text><rect x=\"362\" y=\"52\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"412.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">clients</text><rect x=\"474\" y=\"52\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"524.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">documentation</text><rect x=\"586\" y=\"52\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"636.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">mock server</text><line x1=\"170\" y1=\"73\" x2=\"248\" y2=\"73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"230\" y1=\"73\" x2=\"230\" y2=\"34\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"34\" x2=\"642\" y2=\"34\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"412\" y1=\"34\" x2=\"412\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"524\" y1=\"34\" x2=\"524\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"636\" y1=\"34\" x2=\"636\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"300\" y1=\"94\" x2=\"300\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-flow-ah)\" marker-start=\"url(#l06-flow-ah)\"></line><text x=\"310\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">contract test keeps them in step</text><line x1=\"20\" y1=\"146\" x2=\"680\" y2=\"146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">code-first</text><rect x=\"20\" y=\"190\" width=\"150\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">code and annotations</text><text x=\"95.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">written and reviewed</text><rect x=\"250\" y=\"196\" width=\"150\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"325.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">openapi.yaml</text><line x1=\"170\" y1=\"217\" x2=\"248\" y2=\"217\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><text x=\"209.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">generated</text><rect x=\"474\" y=\"196\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"524.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">documentation</text><rect x=\"586\" y=\"196\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"636.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">clients</text><line x1=\"400\" y1=\"217\" x2=\"472\" y2=\"217\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"436\" y1=\"217\" x2=\"436\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"436\" y1=\"182\" x2=\"636\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"636\" y1=\"182\" x2=\"636\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><text x=\"680\" y=\"258\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">amber: what people write; the rest follows from it</text></svg>", "caption": "The difference is which file people write. Everything else is produced from it, or checked against it."}
```

shelf's document is neither. `rest.py` came first, in lesson 1, and the description was written by
hand afterwards, by reading the code. That is the most common order in practice and the one most
likely to drift: no tool generated the document, and no reviewer saw it before the code existed.
The contract test of the next section is what makes it safe anyway.

## What each one costs

| | design-first | code-first |
|---|---|---|
| what people write | the document | the code, with annotations or types |
| when clients can start | the day the document is agreed, against a mock server | when the code is deployed somewhere |
| what keeps document and code together | a contract test, or a server generated from the document | the generator, on every build |
| the typical failure | the code quietly stops matching the document | the document changes without anybody deciding it should |
| a review of the contract | a diff of the document, read before any code | a diff of the generated document, if somebody commits it |

**Design-first** puts the argument where it is cheapest. Renaming a field in a draft costs an edit;
renaming it after three clients use it costs a version. A **mock server** reads the draft and
answers with its examples, so a front-end team can build against the contract before the back end
has a line of code; Prism is a well-known one. The price is two artefacts that can disagree, and
nothing but a test to notice when they do.

**Code-first** removes the drift between the routes and the document, because one is printed from
the other. Every language of the back-end track has a way to do it, and none of them is run here:

| your language | a common way to generate the document |
|---|---|
| Python | FastAPI builds it from the type hints of each handler, and serves Swagger UI at `/docs` |
| Java | springdoc-openapi reads a Spring application's controllers |
| Go | swag reads structured comments above each handler |
| JavaScript/Node | `@nestjs/swagger` in NestJS, or `@fastify/swagger` in Fastify |

## The wrong idea about code-first

"The document is generated, so it is always right." It is always right about what the code
**declares**: the routes, the parameter types, the response model a handler names. It knows
nothing about what the code **does** when something goes wrong. Take an exception the framework
turns into a 500 with an HTML page, or a library answering a method nobody wrote a handler for, or
a field set to `null` on one path through the code. None of them is declared, so none of them is
in the document.

shelf has one of those already. The 501 that Python's library sends to `OPTIONS` is in no handler of
`rest.py`, and a generator reading `rest.py` would have left it out just as the hand-written
document did. So the two orders need the same safety net in the end. In code-first the declared
part is free, and the contract test covers the rest; in design-first the contract test covers all of
it.

The other cost of code-first is quieter. A developer renames `price_cents` in a model class, the
tests pass, the generated document changes with it, and nobody decided that the contract should
change. **If the generated document is committed to the repository**, that rename shows up in the
pull request as a diff of the contract, where a reviewer can see it. If it is generated only at
run time, nobody sees it until a client breaks.
