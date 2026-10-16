---
title: The 401 and its challenge
version: 1
---

**HTTP has a conversation for credentials built in, and it starts with the server refusing.** A
request with no credential gets **401 Unauthorized**, and the 401 carries one `WWW-Authenticate`
header per scheme the server would accept. The client picks one and asks again, with an
`Authorization` header. Ask `keys.py` for the books with nothing attached:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:05 GMT
Content-Type: application/json
Content-Length: 37
WWW-Authenticate: Basic realm="shelf"
WWW-Authenticate: Bearer realm="shelf"

{"error": "authentication required"}
```

The two `WWW-Authenticate` lines are the **challenge**. Each starts with a scheme, `Basic` or
`Bearer`, and carries parameters after it; `realm="shelf"` names the protected area, so a client that
holds credentials for several realms on one host knows which to send. A 401 without that header
breaks the contract: the status says "authenticate" and nothing says how.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Two lifelines, curl on the left and keys.py on the right. First curl sends GET /v1/books with no credential. keys.py answers 401 Unauthorized with two WWW-Authenticate headers, Basic realm=&quot;shelf&quot; and Bearer realm=&quot;shelf&quot;. curl sends the same request again with Authorization: Basic and the encoded name and password. keys.py answers 200 OK with the books.\"><defs><marker id=\"l07-ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"15\" width=\"120\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><rect x=\"540\" y=\"15\" width=\"120\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">keys.py</text><line x1=\"100\" y1=\"49\" x2=\"100\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"600\" y1=\"49\" x2=\"600\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"100\" y1=\"80\" x2=\"598\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l07-ch-ah)\"></line><text x=\"350\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /v1/books</text><text x=\"115\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1  no credential</text><line x1=\"600\" y1=\"130\" x2=\"102\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l07-ch-ah)\"></line><text x=\"350\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">401 Unauthorized</text><text x=\"350\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">WWW-Authenticate: Basic realm=&quot;shelf&quot;</text><text x=\"350\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">WWW-Authenticate: Bearer realm=&quot;shelf&quot;</text><text x=\"585\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2  the challenge: which schemes</text><line x1=\"100\" y1=\"210\" x2=\"598\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l07-ch-ah)\"></line><text x=\"350\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /v1/books</text><text x=\"350\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Authorization: Basic YW5hOnJpdmVyLWxhbXAtNDI=</text><text x=\"115\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3  the response to the challenge</text><line x1=\"600\" y1=\"260\" x2=\"102\" y2=\"260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l07-ch-ah)\"></line><text x=\"350\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">200 OK</text><text x=\"350\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the books</text></svg>", "caption": "A 401 is not only a refusal: its WWW-Authenticate headers say which schemes would be accepted, and the next request answers with one of them."}
```

The answer to the challenge has the same shape in reverse. **`Authorization` carries a scheme, a
space and the credentials**, and `curl -u` builds the Basic one for you:

```
ana@api:~/shelf$ curl -si -u ana:river-lamp-42 localhost:8000/v1/whoami
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:05 GMT
Content-Type: application/json
Content-Length: 34

{"kind": "person", "name": "ana"}
```

`/v1/whoami` is there so you can ask the server what it concluded. It knows a person called `ana`,
and the section on Basic shows the header that told it so.

## 401 or 403

The name is a historical accident. **401 means unauthenticated**: no credential came, or the one that
came proved nothing. Sending a valid one may change the answer. **403 Forbidden means unauthorised**:
the server knows who you are and the answer is still no, so sending the same credential again is
pointless. A client that gets a 401 should log in again or ask the user; a client that gets a 403
should stop and show the refusal.

Getting it backwards costs something either way. A 403 for a missing token tells a client to give up
on a request that would have worked after a login. A 401 for a forbidden action sends a client round a
login loop it cannot leave: it signs in, asks, gets a 401, signs in again.

One kind of credential has no scheme of its own. `keys.py` takes API keys in an `X-API-Key` header
rather than in `Authorization`, as many APIs do, and there is no standard challenge for that header,
which is why the 401 above does not mention it. A client learns that the API takes keys from the
documentation, and lesson 6's OpenAPI file has a place to say it: `securitySchemes` with `type:
apiKey`, `in: header` and the header's name.
