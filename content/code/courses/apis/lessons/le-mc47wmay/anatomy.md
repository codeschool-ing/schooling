---
title: The anatomy of a document
version: 1
---

**An OpenAPI document is one object, nested a few levels deep, and every level answers one
question.** Which API is this? Which addresses does it have? What does each method do at each
address? What comes back, with which code? The answers sit inside one another in that order,
and the pieces used in more than one place are written once, at the bottom, and pointed at.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 340\" role=\"img\" aria-label=\"The nesting of shelf&#x27;s OpenAPI document. At the top level sit openapi, info, servers, paths and components. Inside paths is the address /books/{id}; inside it the operation get; inside that responses; inside that the code &quot;200&quot;; inside that content, application/json and finally a schema that is only a $ref. The $ref points across to components, where schemas holds Book, NewBook and Error, and responses and parameters hold the pieces used more than once.\"><defs><marker id=\"l06-nest-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"680\" height=\"320\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"22\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">openapi.yaml</text><rect x=\"130\" y=\"16\" width=\"104\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">openapi: 3.1.0</text><rect x=\"242\" y=\"16\" width=\"104\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"294.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">info</text><rect x=\"354\" y=\"16\" width=\"104\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"406.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">servers</text><rect x=\"22\" y=\"52\" width=\"420\" height=\"268\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">paths</text><text x=\"432\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one entry per address</text><rect x=\"34\" y=\"80\" width=\"396\" height=\"230\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/books/{id}</text><text x=\"196\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parameters</text><rect x=\"46\" y=\"108\" width=\"372\" height=\"192\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"56\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">get</text><text x=\"408\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">an operation; put, patch and delete sit beside it</text><rect x=\"58\" y=\"136\" width=\"348\" height=\"154\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"68\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">responses</text><rect x=\"70\" y=\"164\" width=\"324\" height=\"116\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;200&quot;</text><text x=\"384\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one entry per status code</text><rect x=\"82\" y=\"192\" width=\"300\" height=\"78\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"92\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">content: application/json</text><rect x=\"94\" y=\"222\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"194.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">schema: $ref</text><rect x=\"460\" y=\"52\" width=\"218\" height=\"268\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">components</text><text x=\"668\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">written once</text><rect x=\"472\" y=\"80\" width=\"194\" height=\"120\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">schemas</text><rect x=\"484\" y=\"106\" width=\"170\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"569.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Book</text><rect x=\"484\" y=\"136\" width=\"170\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"569.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NewBook</text><rect x=\"484\" y=\"166\" width=\"170\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"569.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Error</text><rect x=\"472\" y=\"210\" width=\"194\" height=\"44\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"482\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">responses</text><text x=\"482\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NotFound, Invalid, …</text><rect x=\"472\" y=\"264\" width=\"194\" height=\"44\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"482\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">parameters</text><text x=\"482\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Id</text><line x1=\"294\" y1=\"240\" x2=\"482\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l06-nest-ah)\"></line></svg>", "caption": "Every key is a box inside another one, and $ref is the one way out of the nesting: it names a place elsewhere in the same document."}
```

It is written in YAML or in JSON, and the choice changes nothing: YAML is the same data with less
punctuation, which is why people writing by hand prefer it and programs that generate a document
usually write JSON. The next section turns shelf's YAML into JSON with one line of Python to show
it.

## The top level

| key | what it holds | required |
|---|---|---|
| `openapi` | the version of the specification the document follows, such as `3.1.0` | yes |
| `info` | the API's `title` and the document's own `version`, plus an optional `description` | yes |
| `servers` | the base addresses the paths are relative to | no; without it, `/` |
| `paths` | every address and what it does | one of `paths`, `components` or `webhooks` |
| `components` | schemas, responses, parameters and the rest, defined once | as above |
| `security`, `tags` | who may call it, and how the operations are grouped on a page | no |

`info.version` trips people up once. It is not the OpenAPI version and it is not the API's `/v1`.
It is the version of this description, and it changes when the description does, even for a
fixed typo in a summary.

## From an address to a schema

Under `paths`, each key is an address, and a part in braces is a **path parameter**:
`/books/{id}` covers `/books/1` and `/books/99`. Under each address sits one **operation** per
method, named in lower case: `get`, `post`, `put`, `patch`, `delete`, plus `head`, `options` and
`trace`. A method that is not listed is a method the document does not describe, which is
different from a method the server refuses, and the contract test in this lesson runs into exactly
that difference.

An operation carries four things worth knowing by name:

- `operationId`, a name for the operation that is unique in the document. A person can ignore
  it; a code generator turns it into a function name, so it is part of the contract for anybody
  generating a client.
- `parameters`, each with a `name`, an `in` (`path`, `query`, `header` or `cookie`) and a
  `schema`. A path parameter must say `required: true`. A list of parameters written beside the
  methods, at the address's own level, applies to all of them.
- `requestBody`, what the client sends, by media type: `content`, then `application/json`,
  then a `schema`.
- `responses`, keyed by status code, each with a `description` and, when there is a body,
  `content` laid out like the request's. A response may also list `headers`.

**The status codes are keys and they must be quoted**, `"200"` and not `200`. The specification
asks for text, and YAML reads a bare number as a number; some tools forgive it and some do not.
Instead of a code, `default` covers every code not listed, which the section on errors weighs.

## `components` and `$ref`

The obvious way to describe the book that `GET /books/1` returns is to write its seven fields
under that response. Then `GET /books` needs them again inside an
array, and so do the answers to POST, PUT and PATCH and the books of one author: six copies, which
will disagree by the second edit.

So schemas, responses, parameters and the rest are written once under `components`, and used with
**`$ref`**:

```yaml
schema: {$ref: "#/components/schemas/Book"}
```

The value is a **pointer**, not a copy: `#` is the root of this document, and each segment after it
is a key, so it reads as "the `Book` under `schemas` under `components`". A tool follows it when it
needs the schema. If nothing is there, the document is broken, and the validator two sections on
says so. A pointer may also name another file, `./book.yaml#/Book`, which is how a large API splits
its description; shelf's fits in one.

What sits at the end of a pointer under `schemas` is plain **JSON Schema**. From 3.1 on, OpenAPI
uses JSON Schema as it is, the same language `python3-jsonschema` reads, which is why this lesson
can check shelf's answers with a library that knows nothing about OpenAPI. Version 3.0 used a
dialect of its own that differed in details, such as how a field that may be `null` is written, and
that difference is a common reason a tool written for 3.0 misreads a 3.1 file.
