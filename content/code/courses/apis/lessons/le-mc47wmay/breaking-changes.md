---
title: Spotting a breaking change
version: 1
---

**With the contract in a file, a change to the API is a change to that file, and it can be read
before it is deployed.** Lesson 1 drew the line: you can add to an API, and you cannot take away
without breaking the clients that used what you took. A document turns that rule from something a
reviewer has to remember into something two versions of a file can show.

Which side of the line a change falls on depends on two things at once. One is direction: a response
is read by the client, a request is written by it. The other is whether the server now gives more
or asks for more:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"A grid with two axes. Columns: the server promises or accepts more, and the server promises less or demands more. Rows: a response, which the client reads, and a request, which the client sends. Response and more: safe, for instance a new field in Book. Response and less: breaking, for instance price_cents removed or renamed. Request and accepts more: safe, for instance a new optional field or a looser pattern. Request and demands more: breaking, for instance a new required field or a stricter ISBN pattern.\"><text x=\"330\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the server promises or accepts more</text><text x=\"565\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the server promises less or demands more</text><text x=\"100\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a response</text><text x=\"100\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the client reads it</text><text x=\"100\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a request</text><text x=\"100\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the client sends it</text><rect x=\"214\" y=\"46\" width=\"232\" height=\"118\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">safe</text><text x=\"330\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a new field in Book</text><text x=\"330\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cover_url: {type: string}</text><text x=\"330\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a new enum value or status code: ask first</text><rect x=\"450\" y=\"46\" width=\"232\" height=\"118\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"566\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">breaking</text><text x=\"566\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a field removed or renamed</text><text x=\"566\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">price_cents → price</text><rect x=\"214\" y=\"168\" width=\"232\" height=\"104\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">safe</text><text x=\"330\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a new optional field</text><text x=\"330\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a looser rule</text><rect x=\"450\" y=\"168\" width=\"232\" height=\"104\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"566\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">breaking</text><text x=\"566\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a new required field</text><text x=\"566\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a stricter pattern on isbn</text></svg>", "caption": "Whether a change breaks depends on two things at once: which way the data flows, and whether the server gives more or asks more."}
```

The two rows are mirrors of each other. **In a response, the server may give more and must not give
less**, because a client reads what it was promised. **In a request, it may accept more and must not
demand more**, because a client sends what it was told to send. A stricter ISBN pattern is a
promise of more in a response, which no reader minds, and a demand for more in a request, where some
client somewhere sends hyphens.

## A change, as a diff

Lesson 1's version 2 replaced `price_cents` with a `price` object. Suppose somebody made a smaller
change of the same kind to version 1's document instead, renaming the field to `price` with one
`sed`, into a new file:

```
ana@api:~/shelf$ sed 's/price_cents/price/' openapi.yaml > next.yaml
ana@api:~/shelf$ diff openapi.yaml next.yaml
153c153
<       required: [isbn, title, author_id, year, price_cents]
---
>       required: [isbn, title, author_id, year, price]
159c159
<         price_cents: {type: integer, minimum: 0}
---
>         price: {type: integer, minimum: 0}
169c169
<         price_cents: {type: integer, minimum: 0}
---
>         price: {type: integer, minimum: 0}
173c173
<       required: [id, isbn, title, author_id, year, price_cents, stock]
---
>       required: [id, isbn, title, author_id, year, price, stock]
180c180
<         price_cents: {type: integer, minimum: 0}
---
>         price: {type: integer, minimum: 0}
```

`diff` reports five changed lines. The document is still valid, and the validator says so:

```
ana@api:~/shelf$ .venv/bin/openapi-spec-validator next.yaml
next.yaml: OK
```

**A valid document can be a breaking change**, and this one breaks clients of shelf in three
different ways. Lines 153 and 159 belong to `NewBook`, which is a request: a client that creates or
replaces a book sends `price_cents`, which `additionalProperties: false` now refuses, and does not
send `price`, which `required` now demands. Line 169 is `BookChange`, another request, so a PATCH
that changes a price stops working. Lines 173 and 180 are `Book`, a response, and every client that
reads a price finds nothing where it looks.

To know that, you needed the name of the schema each line sits in, and whether that schema is sent
or received. Neither is on the line. **`diff` sees text, and the question is about the structure**:
`Book` is a response because the operations under `paths` use it in their `responses`, far up the
file from the line that changed.

## Tools that follow the references

A breaking-change checker reads both documents, follows every `$ref` from each operation, and
classifies each difference with the two questions of the figure above. oasdiff is a widely used
one, written in Go, and openapi-diff another; neither is in Ubuntu's archive, and neither was run
for this lesson. Given these two files, a checker of that kind is built to report the removed
response property and the new required request property as breaking, by operation, which is the
list a reviewer actually needs.

The place to run one is the same as the validator's: in CI, comparing the document in a pull request
with the one on the main branch, and failing the build on a breaking change that does not come
with a new version. That is the habit lesson 1's version 2 asked for, made into a check: a breaking
change is allowed, at a new address, and the tool makes sure it did not happen anywhere else.
