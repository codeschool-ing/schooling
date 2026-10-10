---
title: Writing the contract down
version: 1
---

**shelf already has a contract, and nobody has written it down.** Every API does. The addresses it
answers, the methods each one takes, the fields of a book and the status codes of every refusal
are fixed the moment the server runs, because a client that depends on them breaks when they
change. What varies is where the contract lives. For shelf it lives in about 200 lines of
`rest.py`, and the only ways to learn it are to read Python or to send requests and watch.

The common picture is that documentation is a page written for people, after the code, by whoever
has time. That page matters, but people are one reader of three. A contract written in a
format a program can read serves all of them:

| reader | what it needs | what it does with the document |
|---|---|---|
| a person | which addresses exist, what to send, what comes back | reads a rendered page and writes a client |
| a tool | every field, type and code, without ambiguity | draws the page, generates client code, checks requests at a gateway |
| a test | the same, as rules it can apply | calls the API and fails when an answer breaks the document |

**The third reader is what keeps the other two honest.** A page for people is true on the day it
is written. After that, nothing notices when a field is renamed in the code and not on the page,
and the page goes on reading perfectly. A document that a test compares with the running API fails in the
same commit that makes it untrue. That is what **living documentation** means in this lesson:
documentation that fails when it stops being true.

For shelf, "every field and every code" is a definite list. Lesson 1 met all of it, one section at a
time: four addresses under `/v1`, eight operations on them, the seven fields of a book,
the three of an author, and the codes 200, 201, 204, 400, 404, 405, 409, 415 and 422. This lesson
puts that list in one file, `openapi.yaml`, and then makes programs read it.

## OpenAPI and Swagger

The format is the **OpenAPI Specification**, and you will hear it called Swagger just as often,
because that was its name until 2015. Swagger began as a specification with tools around it; in
2015 the specification was handed to the OpenAPI Initiative, a project of the Linux Foundation,
and renamed. Version 2.0 is the last one called Swagger, 3.0 (2017) is the first called OpenAPI,
and 3.1 (2021) is the one this lesson writes.

The tools kept the old name. So today the two words mean different things:

| name | what it is |
|---|---|
| **OpenAPI** | the specification: the rules a description document follows |
| **Swagger UI**, **Swagger Editor**, **Swagger Codegen** | tools that read such a document, maintained by a company, SmartBear |

The first line of a document tells you which generation it is. A file that opens with
`swagger: "2.0"` is the old format, still common in older projects, and one that opens with
`openapi: 3.1.0` is the current one. "The Swagger file" usually means either, which is harmless in
conversation and worth correcting in a ticket, because a tool that reads 3.1 may refuse 2.0.

OpenAPI describes APIs over HTTP, the kind lesson 1 built. The other styles of this course carry
contracts of their own: GraphQL's schema in lesson 3, the `.proto` file of gRPC in lesson 4 and
the WSDL of SOAP in lesson 5. The idea is the same in all four, and so is the reason it matters:
**a contract only a person can read is a contract only a person can check**, and people check
irregularly.
