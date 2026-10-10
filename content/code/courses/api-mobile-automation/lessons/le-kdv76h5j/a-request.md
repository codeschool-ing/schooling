---
title: What a request and a response are made of
version: 1
---

**An HTTP exchange is two messages of plain text.** The client sends a request; the server sends a
response. Each has the same three parts: a first line, a block of headers, and an optional body
after a blank line. That is the whole protocol as far as a tester needs it, and curl shows all of
it when asked with `-v`, for verbose:

```
ana@laptop:~/boxoffice$ curl -v localhost:8080/v1/shows/sh-103
* Uses proxy env variable no_proxy == 'localhost,127.0.0.1'
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080
> GET /v1/shows/sh-103 HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< content-type: application/json
< etag: "a2cce3d151c58812"
< Date: Sat, 10 Oct 2026 07:13:49 GMT
< Connection: keep-alive
< Keep-Alive: timeout=5
< Transfer-Encoding: chunked
< 
{"id":"sh-103","title":"O Pagador de Promessas","starts_at":"2026-11-08T18:00:00-03:00","price_cents":6500,"seats_left":4}
* Connection #0 to host localhost left intact
```

curl marks each line by where it came from. Lines starting with `>` are what **curl sent**, lines
starting with `<` are what **boxoffice answered**, and lines starting with `*` are curl talking to
you about the connection. The body, the last line, has no mark at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 264\" role=\"img\" aria-label=\"curl sends boxoffice a request in three parts: the request line GET /v1/shows/sh-103 HTTP/1.1, the headers Host, User-Agent and Accept, and no body. boxoffice answers with a response in the same three parts: the status line HTTP/1.1 200 OK, the headers content-type, etag and Date, and a body holding the show as JSON.\"><defs><marker id=\"f01exchange-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"95\" width=\"110\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><text x=\"75\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">curl</text><rect x=\"570\" y=\"95\" width=\"110\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">server</text><text x=\"625\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice</text><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the request</text><rect x=\"170\" y=\"30\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">request line</text><text x=\"278\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET /v1/shows/sh-103 HTTP/1.1</text><rect x=\"170\" y=\"54\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">headers</text><text x=\"278\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Host, User-Agent, Accept</text><rect x=\"170\" y=\"78\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">body</text><text x=\"278\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">(none: a GET sends no body)</text><line x1=\"130\" y1=\"112\" x2=\"568\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f01exchange-ah)\"></line><text x=\"350\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the response</text><rect x=\"170\" y=\"160\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">status line</text><text x=\"278\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">HTTP/1.1 200 OK</text><rect x=\"170\" y=\"184\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">headers</text><text x=\"278\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">content-type, etag, Date</text><rect x=\"170\" y=\"208\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">body</text><text x=\"278\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">{\"id\":\"sh-103\", ... \"seats_left\":4}</text><line x1=\"568\" y1=\"128\" x2=\"132\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f01exchange-ah)\"></line><text x=\"350\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a blank line separates the headers from the body, in both messages</text></svg>", "caption": "Every HTTP exchange is two messages of the same shape: a first line, headers, and an optional body after a blank line."}
```

Read the request first, the four `>` lines:

- `GET /v1/shows/sh-103 HTTP/1.1` is the **request line**: the method, the path of the thing being
  asked about, and the version of the protocol. The method is the verb; section 07 is about them.
- `Host: localhost:8080` names the server. One machine can answer for many names, and this header
  says which one the client meant.
- `User-Agent` and `Accept` are headers too. `Accept: */*` says curl will take any kind of answer.
- the blank line after them ends the headers. A GET carries no body, so the request ends there.

Then the response, the `<` lines:

- `HTTP/1.1 200 OK` is the **status line**: the version, a three-digit status code, and a short
  phrase for people. Programs read the number and ignore the phrase. Section 08 is about codes.
- the headers say what the body is (`content-type: application/json`), give it a fingerprint
  (`etag`), and carry the date. Section 09 reads them.
- after the blank line comes the **body**, the show as JSON.

## What a tester looks at, in order

The order matters because each part decides how to read the next one.

1. **The status code.** It says whether the request worked before you read anything else. A body
   that looks right under a `500` is not a right answer.
2. **The headers that describe the body**, above all `content-type`. A body of JSON labelled as
   text is a defect even when every field in it is correct, because a client that trusts the label
   will not parse it.
3. **The body**, field by field, against what was expected.

How long the answer took is worth a glance too. curl can print it on its own, in seconds:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{time_total}\n' localhost:8080/v1/shows/sh-103
0.001588
```

Under two thousandths of a second, which is what section 01 meant by fast: no screen, no
animation, nothing between the question and the answer but the server.
