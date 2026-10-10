---
title: Documentation people read
version: 1
---

**The page a developer reads is drawn from the same file the test checks.** Nobody writes it.
A renderer, a JavaScript program running in a browser, reads `openapi.yaml` and lays
out one entry per operation, with its parameters, its request body, its responses and the
schemas behind them. Change the document and the page changes on the next load, so a page drawn this
way is exactly as current as the document the contract test keeps honest.

Two renderers cover most of what you will meet:

| | Swagger UI | Redoc |
|---|---|---|
| layout | one expandable panel per operation, grouped by tag | three columns: navigation, explanation, examples |
| sending requests | yes: **Try it out** fills a form and sends a real request from the browser | no; it is a reference to read |
| suits | developers exploring an API while they build against it | published documentation for outsiders |

Both read the same document unchanged. The words on the page are the document's own: every
`summary` becomes a heading, every `description` a paragraph, and an `example` beside a schema
becomes the sample a reader copies. **A page is only as good as those fields**, and a document with
types and no descriptions renders as a list of field names nobody can act on. shelf's has a summary
on every operation and a description on every response, and nothing longer, because the API is
small. A larger one needs a paragraph on what each error means and when it happens.

## Looking at shelf's

None of this was run for the lesson: the machine it was recorded on has no browser, and there is no
screenshot here for that reason. What follows is how you can look at yours.

The VM has no desktop, so the browser is the one on your own computer. The quickest way needs no
installation at all. Print the document in the VM with `cat openapi.yaml` and copy it from the
terminal. Paste it into the left half of the Swagger Editor at `editor.swagger.io`, and the right
half is Swagger UI, drawn from what you pasted. The Swagger Editor is a page somebody else runs. shelf's
document describes nothing private, but a company's internal API would be described to a stranger
that way, and for those the same tools exist as programs you run yourself.

## Why "Try it out" will not reach shelf

Open an operation, press **Try it out** and send it, and it would fail. This was not run either,
but each of the three reasons can be seen without a browser, and none of them is about the
document.

The document's `servers` says `http://127.0.0.1:8000/v1`. In a browser on your computer, `127.0.0.1`
is your computer, and shelf is not running there. It runs inside the VM, which has an address of
its own on a network your computer shares with it. `multipass info api` prints it, on
the line `IPv4`, and inside the VM `ip -4 addr` shows it whatever the hypervisor.

Changing `servers` to that address is not enough, because `rest.py` listens on `127.0.0.1` inside the
VM, which is the VM's own loopback. Lesson 1 chose that so that nothing outside the machine can
reach the API, and it holds for your browser too. A server meant to be reached from outside has to
listen on an address the outside can reach: the VM's own, or `0.0.0.0` for all of them. The course
leaves `rest.py` as it is.

And even listening on the right address, the page is served from one origin and shelf from
another, so the browser asks shelf, through CORS headers, whether the page may read its answers.
For a POST with a JSON body it asks first with an `OPTIONS` request, which `rest.py` answers with the
501 the contract test found. That conversation, and how a server should answer it, is lesson 13.

**So the page is for reading, and `curl` stays the tool for calling shelf in this course.** Reading
is what the page does best anyway. The panel for `POST /books` would show the five required fields,
the optional `stock` and the four refusals with their meanings, which is what somebody writing a
client wants to see before the first line.
