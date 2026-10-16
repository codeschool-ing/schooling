---
title: Scopes, and what a token may do
version: 1
---

**A token does not have to carry everything its owner may do.** When Ana lets an app show her orders
on her phone, the app needs to read them and nothing more. If the token she gives it could also
place orders, then a bug in the app, or the token leaking from it, spends her money. So the token
carries **scopes**, a list of what it may be used for, and the API checks the scopes as well as the
person.

The word comes from OAuth, which lesson 9 draws in full: the app asks for scopes, Ana approves them,
and the token the app receives lists them. This section is about what the API does with that list
once a request arrives.

**The effective permission is the intersection.** A request may do what the person may do AND what
the token was given, and `caller` computes exactly that with Python's set operator:
`ROLES.get(role, set()) & scopes`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 280\" role=\"img\" aria-label=\"Two tokens and the permissions each ends up with. Ana&#x27;s role grants orders:read, orders:create and orders:cancel; the token she gave an app carries only orders:read, so the app can only read. Bruno&#x27;s role grants the same three; his token carries those three and orders:refund, and since his role lacks orders:refund, the effective set is the three his role grants.\"><text x=\"280\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">demo-ana-app: Ana, through an app</text><text x=\"550\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">demo-bruno: Bruno, asking for more</text><text x=\"210\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">role</text><text x=\"280\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">token</text><text x=\"350\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">effective</text><text x=\"480\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">role</text><text x=\"550\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">token</text><text x=\"620\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">effective</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders:read</text><line x1=\"20\" y1=\"111\" x2=\"680\" y2=\"111\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"203\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"273\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"343\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"473\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"543\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"613\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders:create</text><line x1=\"20\" y1=\"149\" x2=\"680\" y2=\"149\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"203\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"273\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"343\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"473\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"543\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"613\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders:cancel</text><line x1=\"20\" y1=\"187\" x2=\"680\" y2=\"187\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"203\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"273\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"343\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"473\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"543\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"613\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders:refund</text><line x1=\"20\" y1=\"225\" x2=\"680\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"203\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"273\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"343\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"473\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"543\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"613\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><line x1=\"415\" y1=\"40\" x2=\"415\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"350\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a scope the role lacks adds nothing; a scope left out takes something away</text></svg>", "caption": "What a request may do is what the person may do AND what the token was given: an intersection."}
```

Ana's app token reads her orders as Ana does, including order 5, placed in the previous section:

```
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-ana-app' localhost:8000/orders | jq -c '.[] | {id, status}'
{"id":1,"status":"cancelled"}
{"id":2,"status":"shipped"}
{"id":5,"status":"placed"}
```

It is refused when it tries to place one:

```
ana@api:~/shelf$ curl -si -X POST -H 'Authorization: Bearer demo-ana-app' -H 'Content-Type: application/json' -d '{"book_id": 1, "quantity": 1}' localhost:8000/orders
HTTP/1.1 403 Forbidden
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 52
WWW-Authenticate: Bearer error="insufficient_scope", scope="orders:create"

{"error": "this token's scope lacks orders:create"}
```

The 403 says which half refused. Ana's role has `orders:create`, so it is the token that lacks it,
and the API answers the way RFC 6750, the standard for bearer tokens, describes: `WWW-Authenticate`
with `error="insufficient_scope"` and the scope that was needed. A client can read that and ask Ana
for a token with more, which is a different conversation from telling her she may not.

The right half of the figure is Bruno's token, which claims `orders:refund`. "Functions only some
may call" already showed his refund refused with `the role customer lacks orders:refund`. **A token
can narrow what its owner may do and can never widen it.** An API that read the scope list alone,
without the role, would let anybody refund any order the day they got a token issued with the right
word in it.
