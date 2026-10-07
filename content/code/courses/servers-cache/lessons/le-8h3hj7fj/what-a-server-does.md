---
title: What a web server does
version: 1
---

A common picture of a web server is a machine: a box in a rack that "is" the website. The box is
the least interesting part. **A web server is a program that listens on a port, reads HTTP requests
and writes HTTP responses**, and everything this course configures is a decision about what that
program does between the reading and the writing.

For every request it has three kinds of answer:

- **a file from disk.** The request names a path, the server maps it to a file under a directory and
  sends the bytes. A stylesheet, a picture, a page that never changes. This is called serving
  **static** content, and a web server does it faster than anything you could write yourself.
- **somebody else's answer.** The request is for something a program has to compute, such as a
  price that lives in a database. The web server passes the request to that program and passes
  the answer back. Here it is acting as a **reverse proxy**, and lesson 2 is about nothing else.
- **an answer of its own.** A redirect, a `404`, a refusal because the request was too large, a
  copy of a response it kept from earlier. The last one is a **cache**, and it is the subject of
  lessons 5 to 11.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"A request arrives at the web server, which answers it in one of three ways: from a file on disk, by passing it to the application and returning its answer, or with an answer of its own such as a redirect, an error or a cached copy.\"><defs><marker id=\"f3a-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"120\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">browser</text><text x=\"80.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /...</text><rect x=\"230\" y=\"80\" width=\"170\" height=\"96\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">web server</text><text x=\"315.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">nginx, apache, caddy</text><line x1=\"140\" y1=\"128\" x2=\"228\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f3a-ah)\"></line><rect x=\"500\" y=\"16\" width=\"180\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a file from disk</text><text x=\"590.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/var/www/ipe/...</text><rect x=\"500\" y=\"100\" width=\"180\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the application</text><text x=\"590.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">127.0.0.1:8001</text><rect x=\"500\" y=\"184\" width=\"180\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"590.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own answer</text><text x=\"590.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">301 · 404 · 413 · cache</text><line x1=\"400\" y1=\"104\" x2=\"498\" y2=\"44\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f3a-ah)\"></line><line x1=\"400\" y1=\"128\" x2=\"498\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f3a-ah)\" marker-start=\"url(#f3a-ah)\"></line><line x1=\"400\" y1=\"152\" x2=\"498\" y2=\"212\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f3a-ah)\"></line><text x=\"450\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">static</text><text x=\"450\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">proxy</text><text x=\"428\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lessons 5-11</text></svg>", "caption": "Every answer a web server gives is one of three kinds. Lesson 1 is the first, lesson 2 the second, and most of this course is the third."}
```

The program that sits behind the proxy is usually called the **application server** or the
**origin**. This course has one: Ipê Livros, a small bookshop written for it. Its catalogue is a
Python program that answers on `127.0.0.1:8001` and `127.0.0.1:8002`, and its database is
deliberately slow, so that a cache in front of it has something to save. Every answer it gives
names itself in a header:

```
ana@web:~$ curl -sI localhost:8002/api/books/1
HTTP/1.1 200 OK
Server: ipe-shop/1.0
Date: Wed, 07 Oct 2026 03:11:19 GMT
X-Served-By: shop2
Content-Type: application/json
ETag: "806121fbab2ee803"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Content-Length: 124
```

**Why put a web server in front at all**, when the application can already speak HTTP? Because the
work around the application is the same for every application, and doing it well is hard. Holding
ten thousand slow connections open, speaking TLS, compressing, refusing a request with a 2 GB body,
serving files with the kernel's help, spreading load over two copies, keeping a cache. A web server
does those once, in tested code, and your application gets to answer only the questions only it
can answer.

This lesson installs the three servers you will meet most, Nginx, Apache and Caddy, and makes each
one serve the bookshop's static front. The rest of the course uses Nginx, because it is the one you
are most likely to find in front of somebody else's application, and points out where the other
two do a thing differently.
