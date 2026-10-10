---
title: shelf's specification
version: 1
---

**This is the whole of version 1 of shelf, as a document.** Every address `rest.py` answers under
`/v1`, every method each one takes, the bodies going both ways and the codes a client can act on.
Version 2 is left out. It is one read-only resource, and describing both versions in one file would
put a version in front of every path for its sake; a second version usually gets a document of its
own.

Save it beside the two Python files, in the first terminal, with `nano openapi.yaml`. It is long
because it is complete, and each part has a note beside it; the copy button takes the whole file
without the notes.

```schooling-example
{
  "language": "yaml",
  "file": "shelf/openapi.yaml",
  "parts": [
    {
      "code": "# shelf/openapi.yaml\nopenapi: 3.1.0\ninfo:\n  title: shelf\n  version: 1.0.0\n  description: The bookshop's REST API, version 1, as rest.py serves it.\nservers:\n  - url: http://127.0.0.1:8000/v1",
      "note": "`openapi` says which version of the specification the document follows. `info.version` is a different number: the version of this description, which you raise whenever it changes. The server's address ends in `/v1`, so every path below is relative to it."
    },
    {
      "code": "\npaths:\n  /books:\n    get:\n      operationId: listBooks\n      summary: Every book, or the books of one author\n      parameters:\n        - name: author_id\n          in: query\n          required: false\n          schema: {type: integer}\n      responses:\n        \"200\":\n          description: The books, ordered by id\n          content:\n            application/json:\n              schema:\n                type: array\n                items: {$ref: \"#/components/schemas/Book\"}",
      "note": "`paths` has one entry per address and, under each, one **operation** per method. `GET /books` takes an optional `author_id` and answers 200 with an array of books. The `$ref` points at the schema of a book, written once near the end."
    },
    {
      "code": "    post:\n      operationId: createBook\n      summary: Add a book\n      requestBody:\n        required: true\n        content:\n          application/json:\n            schema: {$ref: \"#/components/schemas/NewBook\"}\n      responses:\n        \"201\":\n          description: Created\n          headers:\n            Location:\n              required: true\n              description: The new book's address\n              schema: {type: string}\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Book\"}\n        \"400\": {$ref: \"#/components/responses/BadJson\"}\n        \"409\": {$ref: \"#/components/responses/Conflict\"}\n        \"415\": {$ref: \"#/components/responses/NotJson\"}\n        \"422\": {$ref: \"#/components/responses/Invalid\"}",
      "note": "Creating a book: what the client sends in `requestBody`, and what comes back. The 201 lists `Location` as a required header, and the four refusals point at reusable responses. The codes are in quotes because the specification wants them as text, and YAML would read a bare `201` as a number."
    },
    {
      "code": "\n  /books/{id}:\n    parameters:\n      - $ref: \"#/components/parameters/Id\"\n    get:\n      operationId: getBook\n      summary: One book\n      responses:\n        \"200\":\n          description: The book\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Book\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}",
      "note": "`{id}` makes the path a template. A `parameters` list at this level applies to every operation under the path, and the parameter itself is defined once in `components`, since three addresses use it."
    },
    {
      "code": "    put:\n      operationId: replaceBook\n      summary: Replace a book; a field left out is not kept\n      requestBody:\n        required: true\n        content:\n          application/json:\n            schema: {$ref: \"#/components/schemas/NewBook\"}\n      responses:\n        \"200\":\n          description: The book as it is now\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Book\"}\n        \"400\": {$ref: \"#/components/responses/BadJson\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}\n        \"409\": {$ref: \"#/components/responses/Conflict\"}\n        \"415\": {$ref: \"#/components/responses/NotJson\"}\n        \"422\": {$ref: \"#/components/responses/Invalid\"}\n    patch:\n      operationId: changeBook\n      summary: Change some fields of a book\n      requestBody:\n        required: true\n        content:\n          application/json:\n            schema: {$ref: \"#/components/schemas/BookChange\"}\n      responses:\n        \"200\":\n          description: The book as it is now\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Book\"}\n        \"400\": {$ref: \"#/components/responses/BadJson\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}\n        \"409\": {$ref: \"#/components/responses/Conflict\"}\n        \"415\": {$ref: \"#/components/responses/NotJson\"}\n        \"422\": {$ref: \"#/components/responses/Invalid\"}",
      "note": "PUT and PATCH differ where rest.py makes them differ, in the body. PUT takes a `NewBook`, where every field but `stock` is required, and PATCH a `BookChange`, where none is."
    },
    {
      "code": "    delete:\n      operationId: deleteBook\n      summary: Remove a book\n      responses:\n        \"204\":\n          description: Gone, and no body\n        \"404\": {$ref: \"#/components/responses/NotFound\"}",
      "note": "A response with a `description` and no `content` is how the specification says there is no body, which is what 204 means."
    },
    {
      "code": "\n  /authors/{id}:\n    parameters:\n      - $ref: \"#/components/parameters/Id\"\n    get:\n      operationId: getAuthor\n      summary: One author\n      responses:\n        \"200\":\n          description: The author\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Author\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}\n\n  /authors/{id}/books:\n    parameters:\n      - $ref: \"#/components/parameters/Id\"\n    get:\n      operationId: listAuthorBooks\n      summary: The books of one author\n      responses:\n        \"200\":\n          description: The author's books, ordered by id\n          content:\n            application/json:\n              schema:\n                type: array\n                items: {$ref: \"#/components/schemas/Book\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}",
      "note": "The two author addresses. rest.py has no list of authors, so the document has none either; describing `GET /authors` would promise an answer the server gives as a 404."
    },
    {
      "code": "\ncomponents:\n  parameters:\n    Id:\n      name: id\n      in: path\n      required: true\n      schema: {type: integer, minimum: 1}",
      "note": "`components` holds everything defined once and referenced by `$ref`. A path parameter must say `required: true`, because an address with a hole in it is not an address."
    },
    {
      "code": "\n  schemas:\n    NewBook:\n      type: object\n      additionalProperties: false\n      required: [isbn, title, author_id, year, price_cents]\n      properties:\n        isbn: {type: string, pattern: \"^[0-9]{13}$\"}\n        title: {type: string}\n        author_id: {type: integer}\n        year: {type: integer}\n        price_cents: {type: integer, minimum: 0}\n        stock: {type: integer, minimum: 0, default: 0}\n    BookChange:\n      type: object\n      additionalProperties: false\n      properties:\n        isbn: {type: string, pattern: \"^[0-9]{13}$\"}\n        title: {type: string}\n        author_id: {type: integer}\n        year: {type: integer}\n        price_cents: {type: integer, minimum: 0}\n        stock: {type: integer, minimum: 0}",
      "note": "What a client may send. In OpenAPI 3.1 a schema is **JSON Schema**, the language `python3-jsonschema` reads. `additionalProperties: false` makes an unknown field an error, as rest.py's 422 for `colour` does. The ISBN's `pattern` is a rule rest.py does not check, and the contract test finds out what that costs."
    },
    {
      "code": "    Book:\n      type: object\n      required: [id, isbn, title, author_id, year, price_cents, stock]\n      properties:\n        id: {type: integer}\n        isbn: {type: string, pattern: \"^[0-9]{13}$\"}\n        title: {type: string}\n        author_id: {type: integer}\n        year: {type: integer}\n        price_cents: {type: integer, minimum: 0}\n        stock: {type: integer, minimum: 0}\n    Author:\n      type: object\n      required: [id, name, country]\n      properties:\n        id: {type: integer}\n        name: {type: string}\n        country: {type: string, pattern: \"^[A-Z]{2}$\"}\n    Error:\n      type: object\n      required: [error]\n      properties:\n        error: {type: string, description: A sentence for a person to read}",
      "note": "What the server sends back. A `Book` always carries all seven fields and does not forbid others, so a field added to the response one day does not fail a client that validates against this schema. `Error` is the one shape every refusal from rest.py has."
    },
    {
      "code": "\n  responses:\n    BadJson:\n      description: The body is not JSON, or not a JSON object\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}\n    NotJson:\n      description: The body is not labelled application/json\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}\n    NotFound:\n      description: No such book or author\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}\n    Conflict:\n      description: Another book already has this ISBN\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}\n    Invalid:\n      description: The JSON is fine and its content breaks a rule\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}",
      "note": "Five responses that differ only in their description. Written here once, they are eighteen one-line references above instead of eighteen copies of four lines."
    }
  ]
}
```

## What it leaves out, on purpose

A description says what clients may rely on, which is not everything the server happens to do.
Three things `rest.py` does are not in it:

- The 405 answers. `DELETE /v1/books` gets a 405 with an `Allow` header, as lesson 1 showed, but
  the document lists no `delete` under `/books`, and a method it does not list is one a client
  should not send. Describing one would mean listing the method with a 405 as its only answer,
  which advertises an operation nobody can use.
- Version 2, for the reason above.
- The 501 that Python's library sends to `OPTIONS`. Nobody chose it, so nobody would think to
  write it down, and the contract test in this lesson finds it for exactly that reason.

And one thing is in it that `rest.py` does not do. The ISBN's `pattern`, thirteen digits, is the
shop's rule: every book `db.py` created follows it. `rest.py` checks that an ISBN is a string and
nothing more. A document is allowed to say what the API is meant to do, as long as something then
checks whether it does.

## The document is data

Nothing about the file is special to OpenAPI tools. It is YAML, so `python3-yaml` reads it, and once
it is read it can be written out as JSON and handed to `jq`, like any answer from shelf. Its top
level first, then every operation, by method and address:

```
ana@api:~/shelf$ python3 -c 'import json, sys, yaml; json.dump(yaml.safe_load(sys.stdin), sys.stdout)' < openapi.yaml | jq -c 'keys'
["components","info","openapi","paths","servers"]
ana@api:~/shelf$ python3 -c 'import json, sys, yaml; json.dump(yaml.safe_load(sys.stdin), sys.stdout)' < openapi.yaml | jq -r '.paths | to_entries[] | .key as $p | .value | keys_unsorted[] | select(. != "parameters") | ascii_upcase + " " + $p'
GET /books
POST /books
GET /books/{id}
PUT /books/{id}
PATCH /books/{id}
DELETE /books/{id}
GET /authors/{id}
GET /authors/{id}/books
```

Eight operations, and every line is one a client of shelf can send. That list is what a generator
turns into eight functions, what a documentation page turns into eight panels, and what the contract
test checks one request at a time.
