---
title: A first request, and the panes that answer it
version: 1
---

**A request in Postman is the request of lesson 1 with each part in a field of its own.** The method
is a drop-down, the address is a text box, and the headers and the body each have a tab. The answer
comes back split the same way: a status, a time and a size on one line, then the body and the
headers in tabs underneath. Nothing new travels; it is laid out differently.

## Sending it

Open a new HTTP request: the **New** button, then *HTTP*. A tab opens with a long bar across the
top. On its left is the method, set to `GET`; in the middle, the address; on the right, **Send**.
Under the bar sit tabs for the query parameters, the authorization, the headers, the body and the
scripts. Type the address of the shows and send it:

```
http://localhost:8080/v1/shows
```

The second terminal, the one running boxoffice, prints a line for it, as it did for every curl
request: `GET /v1/shows 200`. That line is the proof that the request went out and was answered,
and it is worth a glance whenever the app and the server seem to disagree.

## Reading the answer

The lower half of the window is the response. Read it in the order lesson 1 gave you:

| what you see | where | in the terms of lesson 1 |
|---|---|---|
| `200 OK` | the line above the body, on the right | the status line |
| a time in milliseconds | beside the status | `curl -w '%{time_total}'` |
| a size in bytes | beside the time | the headers and the body together |
| **Headers** tab, with a count | under the status line | the `<` lines of `curl -v` |
| **Body** tab: *Pretty*, *Raw*, *Preview* | under the status line | the JSON that jq laid out |

Hovering over the time breaks it into its parts, and hovering over the size splits headers from
body. Open the Headers tab and look for `content-type: application/json` and `cache-control:
max-age=60`, the two headers that say how to read and keep this answer.

**Pretty is not what the server sent.** It is the body parsed and laid out again, one field per
line, the way jq laid it out. The server sent one line with no spaces. Most days that makes no
difference; when the exact bytes matter, such as a test of whitespace, of field order, or of a body
that is not quite JSON, switch to *Raw*, which is the text as it arrived.

Now ask for a show that does not exist, `http://localhost:8080/v1/shows/sh-999`. The status turns
`404 Not Found`, and the Headers tab says `content-type: application/problem+json`, the error format
of lesson 2. A tester reads the label on an error as carefully as on a success, because a client
decides how to parse the body from it.

## What Postman adds to your request

**Postman sends more headers than you typed.** It adds a `User-Agent` naming itself, an `Accept`, a
`Postman-Token` with a random value, and a few about the connection. They are visible on the
request's Headers tab under a *hidden* toggle, and the Postman Console, opened from the bottom bar,
shows every request exactly as it went out. That matters the day a request works in Postman and
fails in your app: the difference may be a header Postman added that your app does not send.

Do not save this request yet. Section 06 imports a whole collection, with this request already in
it under a name.
