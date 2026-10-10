---
title: The preflight
version: 1
---

**For a request no form could send, the browser asks permission first.** It sends an `OPTIONS`
request to the same address, describing the request it wants to make, and sends that request only if
the answer allows it. The question is called the preflight, and the script never sees it: `fetch`
returns once, with the result of the real request or with the refusal.

The page's "Set the stock to 11" button is that kind of request twice over: its method is PATCH, and
its body is `application/json`. Here is the question the browser asks for it, sent by hand from the
origin on the list:

```
ana@api:~/shelf$ curl -si -X OPTIONS localhost:8000/v1/books/1 -H 'Origin: http://localhost:8080' -H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type'
HTTP/1.1 204 No Content
Server: shelf
Date: Sat, 10 Oct 2026 04:23:17 GMT
Content-Length: 0
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Access-Control-Allow-Origin: http://localhost:8080
Vary: Origin
Allow: GET, PATCH, OPTIONS
Access-Control-Allow-Methods: GET, PATCH
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 600
```

The request carries three headers, and the answer carries four that match them:

| the browser asks | the server answers |
|---|---|
| `Origin`: which page is asking | `Access-Control-Allow-Origin`: the origin allowed to go ahead |
| `Access-Control-Request-Method`: the method it wants to use | `Access-Control-Allow-Methods`: the methods allowed |
| `Access-Control-Request-Headers`: the headers the script set | `Access-Control-Allow-Headers`: the headers allowed |
| | `Access-Control-Max-Age`: how many seconds the browser may remember this answer |

**`Access-Control-Max-Age: 600` saves a round trip.** For ten minutes, a PATCH from that page to that
address goes out with no question in front of it. Browsers cap the number at their own limit, so a
day asked for is not always a day given, and without the header the answer is remembered for a few
seconds only.

The same question from the origin that is not on the list gets an answer too, a 204 with `Allow` for
any client that wants to know the methods, and nothing that says the page may go ahead:

```
ana@api:~/shelf$ curl -si -X OPTIONS localhost:8000/v1/books/1 -H 'Origin: http://127.0.0.1:8080' -H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type' | grep -iE '^(HTTP|allow|access-control|vary)'
HTTP/1.1 204 No Content
Vary: Origin
Allow: GET, PATCH, OPTIONS
```

## What the browser did with each answer

Loaded from `localhost:8080`, the second button printed:

```
PATCH 200 {"id": 1, "title": "Dom Casmurro", "stock": 11}
```

Loaded from `127.0.0.1:8080`, it printed:

```
Access to fetch at 'http://127.0.0.1:8000/v1/books/1' from origin 'http://127.0.0.1:8080' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource.
Failed to load resource: net::ERR_FAILED
PATCH failed: TypeError: Failed to fetch
```

The second message is different from the GET's. It says the **preflight** did not pass, and the
server's terminal says what that meant. These are the five lines the two pages caused, the first
three from the page on the list and the last two from the one that is not:

```
127.0.0.1 - - [10/Oct/2026 01:23:15] "GET /v1/books/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:23:15] "OPTIONS /v1/books/1 HTTP/1.1" 204 -
127.0.0.1 - - [10/Oct/2026 01:23:15] "PATCH /v1/books/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:23:16] "GET /v1/books/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:23:17] "OPTIONS /v1/books/1 HTTP/1.1" 204 -
```

From the page on the list: OPTIONS, then the PATCH. From the other one: the GET that was answered and
thrown away, as the previous section showed, then the OPTIONS, and **no PATCH at all**. The stock was
never changed, because the request that would have changed it never left the browser.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two sequences side by side. On the left, a page on the allowlist: the browser sends OPTIONS, the API answers 204 naming the origin, the browser sends the PATCH, the API answers 200 and the script reads it. On the right, a page not on the list: the same OPTIONS gets a 204 with no Allow-Origin, the PATCH is never sent, and the script gets a TypeError.\"><defs><marker id=\"l13-cors-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"5\" y=\"8\" width=\"340\" height=\"314\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">page at localhost:8080, on the list</text><rect x=\"25\" y=\"42\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"70.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">browser</text><rect x=\"245\" y=\"42\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><line x1=\"70\" y1=\"70\" x2=\"70\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"290\" y1=\"70\" x2=\"290\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"72\" y1=\"104\" x2=\"288\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"180.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">OPTIONS /v1/books/1</text><text x=\"180\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Request-Method: PATCH</text><line x1=\"288\" y1=\"152\" x2=\"72\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"180.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">204</text><text x=\"180\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">Allow-Origin: localhost:8080</text><line x1=\"72\" y1=\"200\" x2=\"288\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"180.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">PATCH {&quot;stock&quot;: 11}</text><line x1=\"288\" y1=\"238\" x2=\"72\" y2=\"238\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"180.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">200 {&quot;stock&quot;: 11}</text><text x=\"175\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the script reads the answer</text><rect x=\"375\" y=\"8\" width=\"340\" height=\"314\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">page at 127.0.0.1:8080, not on the list</text><rect x=\"395\" y=\"42\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">browser</text><rect x=\"615\" y=\"42\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><line x1=\"440\" y1=\"70\" x2=\"440\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"660\" y1=\"70\" x2=\"660\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"442\" y1=\"104\" x2=\"658\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"550.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">OPTIONS /v1/books/1</text><text x=\"550\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Request-Method: PATCH</text><line x1=\"658\" y1=\"152\" x2=\"442\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"550.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">204</text><text x=\"550\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">no Allow-Origin</text><line x1=\"442\" y1=\"200\" x2=\"510\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"504\" y1=\"194\" x2=\"516\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"504\" y1=\"206\" x2=\"516\" y2=\"194\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"528\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">PATCH never sent</text><text x=\"550\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the server never hears of it</text><text x=\"545\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the script gets TypeError</text></svg>", "caption": "The same PATCH from two pages. The preflight is answered both times; only the page whose origin the answer names gets its PATCH sent."}
```

That is the real difference between the two kinds of request. A simple request is sent and its
answer withheld; a preflighted one is not sent unless the server agrees. When the server agrees, the
real request carries `Origin` again and its answer has to name the origin again:

```
ana@api:~/shelf$ curl -si -X PATCH localhost:8000/v1/books/1 -H 'Origin: http://localhost:8080' -H 'Content-Type: application/json' -d '{"stock": 12}' | grep -iE '^(HTTP|access-control|vary)|stock'
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:8080
Vary: Origin
{"id": 1, "title": "Dom Casmurro", "stock": 12}
```

## Two things lesson 1 left behind

Lesson 1's `rest.py` answered `OPTIONS` with **501** and an HTML page, because it defines no such
method. A browser treats a preflight answered with anything but a 2xx status as a refusal, so no
page could ever have sent `rest.py` a PATCH, whatever headers it added later. `secure.py` answers
**204**, with `Allow` for any client and the CORS headers for a page on its list.

The second is the header lesson 7 adds to every request: `Authorization`. It is not on the
browser's safelist, so a page that sends a token triggers a preflight, and the server has to name it
in `Access-Control-Allow-Headers` beside `Content-Type`. Forget it and every authenticated call from
the page fails at the question, while curl works perfectly.
