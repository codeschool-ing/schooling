---
title: What a web framework does, and what it leaves to you
version: 1
---

The common picture of a framework is a big library: a box of functions you call when you need
them. **A framework works the other way round. It calls you.** It owns the part of the program
that waits for a request, reads it, decides which of your functions should answer, and turns what
that function returns into bytes on the wire. You write the functions in the middle, and the
framework decides when they run.

That inversion is the whole difference between Django and `requests`. With `requests` you write
the program and call the library when you want a page. With Django or FastAPI the program already
exists, and you fill in the pieces it asks for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A request arrives at a server process, which hands it to the framework. The framework parses it, matches the path against a table of routes and calls one function the developer wrote. What the function returns goes back through the framework, which builds the response, and out through the server.\"> <defs><marker id=\"fw-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"28\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the network</text> <rect x=\"20\" y=\"40\" width=\"110\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"75\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /hello/ana</text> <text x=\"75\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">200 OK</text> <rect x=\"160\" y=\"40\" width=\"120\" height=\"170\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"220\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the server</text> <text x=\"220\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">listens on a port,</text> <text x=\"220\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reads the bytes</text> <rect x=\"310\" y=\"40\" width=\"390\" height=\"170\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.12\" stroke=\"var(--phosphor)\"></rect> <text x=\"505\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the framework</text> <rect x=\"330\" y=\"82\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"385\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parse the request</text> <rect x=\"460\" y=\"82\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"510\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">match a route</text> <rect x=\"580\" y=\"82\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.25\" stroke=\"var(--amber)\"></rect> <text x=\"630\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">your function</text> <text x=\"630\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hello(name)</text> <rect x=\"330\" y=\"150\" width=\"350\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"505\" y=\"174\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build the response: status, headers, body</text> <path d=\"M130 106 L154 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M280 102 L324 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M440 102 L454 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M560 102 L574 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M630 122 L630 144\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M330 170 L286 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M160 146 L136 146\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <text x=\"505\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Only the highlighted box is yours. The framework decides when it runs.</text> </svg>", "caption": "One request, from the network to your function and back. The server and the framework are separate programs in Python, which is what the WSGI and ASGI section of this lesson is about."}
```

## The jobs, one by one

Between the bytes arriving and your function running there are a dozen jobs, and every web
application needs all of them done by somebody:

| job | what it means |
|---|---|
| **routing** | `/hello/ana` runs `hello` with `name="ana"`; `/goodbye/ana` is a 404 |
| **parsing** | the query string, the headers, a form, a JSON body, an uploaded file |
| **validation** | an age that is a number, an email that looks like one, a field that is missing |
| **responses** | a status code, headers, a body in JSON or HTML |
| **data** | rows in a database, read and written without hand-written SQL everywhere |
| **identity** | who is asking: a session cookie, a token, a password check |
| **permissions** | whether that person may do this particular thing |
| **security defaults** | headers that stop a page being framed, forms that cannot be forged |
| **tooling** | migrations, a shell, a test client, a way to run the thing |

A framework is a set of answers to that table. **Django answers every row itself. FastAPI answers
the first four and leaves the rest to libraries you choose.** Neither is a shortcut: the rows a
framework leaves empty are still rows, and somebody on the team fills them in.

## What you still write

Whatever the framework, three things stay yours: what each URL means, what the data looks like,
and what the rules are. A framework can check that `capacity` is a positive integer; only you know
that an event with forty seats must refuse the forty-first registration. Lesson 4 writes that rule
as a database constraint, which is where a rule that must never break belongs.

## The one thing a framework is not

**A framework is not the server.** In Python the program that listens on a port and the program
that answers the request are two programs with a standard contract between them. Django's
`runserver` and the `uvicorn` command you will meet in a moment are servers; Django and FastAPI are
the applications they call. That split is why lesson 16 can put Django behind Gunicorn and FastAPI
behind Uvicorn without changing a line of either, and the section on WSGI and ASGI shows the
contract itself.
