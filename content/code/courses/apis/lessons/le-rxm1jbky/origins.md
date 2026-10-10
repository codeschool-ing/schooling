---
title: Origins and the same-origin policy
version: 1
---

**An origin is three things taken together: the scheme, the host and the port.** A browser files
every page under its origin, and it will not let a page read what another origin sends back unless
that origin says it may. That rule is the same-origin policy, and CORS, the subject of the next three
sections, is how a server says "it may".

Take the page the next section gives you, `http://localhost:8080/page.html`. Its origin is
`http://localhost:8080`, and the path plays no part. Against it:

| address | same origin? | why |
|---|---|---|
| `http://localhost:8080/other.html` | yes | only the path differs |
| `http://localhost:8000/v1/books/1` | no | the port differs |
| `https://localhost:8080/page.html` | no | the scheme differs |
| `http://127.0.0.1:8080/page.html` | no | the host differs, though it is the same machine |
| `http://api.localhost:8080/` | no | a different host name is a different host |

The fourth row surprises most people. The browser compares the names as strings; it never asks
whether two names lead to the same computer. **The shelf's API and its page are on one machine, under
one name, and they are still two origins**, because the port is part of the origin.

## What the policy blocks, and what it does not

The common belief is that the policy stops a page from sending requests to another site. It does not,
and never did. A page has always been able to put an image from anywhere on screen, load a script from
anywhere, and submit a form to anywhere, and the browser sends all of those. **What the policy blocks
is reading.** A script on one origin may cause a request to another, but the response is kept from it.

Three cases, then:

- **A request a form could send** (a GET, or a POST of form fields) goes out at once, and the
  server answers it. If the answer does not name the page's origin, the browser keeps it from the
  script. The server did the work; only the page went without the result.
- **A request a form could not send** (a PATCH, a JSON body, an `Authorization` header) is
  asked about first, with a separate request the preflight section takes apart. If the answer to the
  question is no, the real request is never sent.
- **Embedding** an image or a script from another origin still works, and the script on the page
  still cannot read the bytes.

The reason for the rule is the person at the keyboard. A browser sends a site's cookies with every
request to that site, whichever page caused it; lesson 8 is about those cookies. Without the policy,
any page you opened in one tab could call your bank's API in your name and read the answer. **The
policy protects the user of the browser, not the server**, and that difference is the root of most
CORS mistakes.

It also explains who enforces it. `curl`, a Python script, a phone app and another server have no
user's cookies to protect and no policy to apply: they read whatever comes back. Only a browser
enforces the same-origin policy, which is why the shelf's curl commands of earlier lessons never met
it.
