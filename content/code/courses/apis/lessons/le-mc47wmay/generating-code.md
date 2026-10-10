---
title: Generating clients and servers
version: 1
---

**A document precise enough for a test is precise enough to write code from.** Every operation has
a method, an address, typed parameters, a typed body and typed answers, and a program can turn that
into code mechanically. Three kinds of code come out of it:

| what is generated | from which part | what you still write |
|---|---|---|
| a **client library** | one function per operation, one type per schema | the program that calls those functions |
| a **server stub** | the routes, the request types, an empty handler per operation | the body of every handler |
| **validation** in front of a server | the schemas of every request body and parameter | nothing; it refuses what the document refuses |

The tools are many and none of them is in Ubuntu's archive, so none is run in this course.
OpenAPI Generator is the broadest, with generators for dozens of languages, and grew out of
Swagger Codegen. Others do one language well: oapi-codegen for Go, openapi-typescript for
TypeScript types, datamodel-code-generator for Python classes.

## What `operationId` turns into

The names in a generated client come from the document. `operationId: createBook` becomes a
function called `createBook`, or `create_book`, depending on the language, and `NewBook` becomes a
type called `NewBook`. That makes some edits to the document breaking for code even when nothing
changes over HTTP. Rename `createBook` to `addBook` because it reads better, and every program built
on the generated client stops compiling the day it regenerates, although `POST /v1/books` behaves
exactly as before. A document that clients generate code from has two contracts in it, the HTTP one
and the names.

## The risks

**Generated code is as right as the document, and more confident than it should be.** shelf's
document says an ISBN is thirteen digits. A client generated with validation turned on would refuse
`978-65-00000-08-5` before sending it, while the server accepts it; a server stub with validation
would refuse what `rest.py` accepts. Neither is wrong about the document, and both disagree with the
API you actually run. The contract test is still what tells you which.

The rest are practical, and each has a habit that answers it:

| the risk | what happens | the habit |
|---|---|---|
| editing generated files | the next generation overwrites the edit, silently | keep generated code in its own directory and never edit it; wrap it instead |
| an unpinned generator | the same document produces different code after an upgrade | pin the generator's version, as this lesson pinned the validator's |
| uneven support | `oneOf`, `anyOf`, `additionalProperties` and nullable fields come out differently, or not at all, between generators | read what was generated for your hardest schema before trusting the rest |
| a stub generated once | the handlers are filled in, the document moves on, and the two drift as if nothing had been generated | regenerate interfaces on every change and implement them, rather than generating a starting point |
| size | a few operations become dozens of files and a new dependency | for a small API, compare with writing the client by hand |

**The last row is a real choice for an API shelf's size.** Eight operations is a client a person
writes in an afternoon. Generating one starts paying when the API has hundreds of operations, several
languages call it, or the document changes every week and nobody can keep a hand-written client in
step. Below that, the document still earns its keep as the thing the test checks and the page people
read, which is what this lesson built.
