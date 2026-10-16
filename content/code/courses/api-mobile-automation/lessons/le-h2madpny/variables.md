---
title: Variables, and which one wins
version: 1
---

**A variable is a name in double braces that Postman replaces before the request leaves.** Write
`{{baseUrl}}/v1/shows` and Postman looks up `baseUrl`, finds `http://localhost:8080`, and sends
`http://localhost:8080/v1/shows`. The server never sees the braces. Variables work anywhere in a
request: the address, a header, the body, the authorization.

The first variable every collection gets is the address of the server, and the reason is the day the
server moves. Twenty requests that each spell out `http://localhost:8080` are twenty edits when the
same tests have to run against a test server. Twenty requests that say `{{baseUrl}}` are one.

## Five places a variable can live

**A name can be defined in more than one place at once, and the narrowest place wins**, whichever
was set last. Most people expect the opposite, that the value written most recently is the one
used, and lose an afternoon to it. Postman has five scopes, from the widest to the narrowest:

| scope | defined in | lives | good for |
|---|---|---|---|
| global | the workspace | until deleted | almost nothing; every collection sees it |
| collection | the collection itself | with the collection | values that belong to this API: an id the requests share |
| environment | the environment chosen in the top-right drop-down | until you switch | what changes from one server to another: the address, credentials |
| data | a CSV or JSON file given to a run | one row, one iteration | many cases through one request (lesson 5) |
| local | a script, while one request runs | that request only | a value computed just before sending (lesson 5) |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 276\" role=\"img\" aria-label=\"Five scopes stacked from widest to narrowest: global, collection, environment, data and local. showId is defined in the collection as sh-103 and in the environment as sh-101, and not in the other three. The request sends sh-101, because the environment is the narrower of the two scopes that define it.\"><defs><marker id=\"f04scopes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"250\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">where showId could be defined</text><text x=\"560\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">its value there</text><rect x=\"100\" y=\"30\" width=\"300\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">global</text><text x=\"250\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the workspace</text><text x=\"540\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not defined</text><rect x=\"115\" y=\"70\" width=\"270\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">collection</text><text x=\"250\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the collection file</text><rect x=\"500\" y=\"74\" width=\"120\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"560\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sh-103</text><rect x=\"130\" y=\"110\" width=\"240\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">environment</text><text x=\"250\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the active environment</text><rect x=\"500\" y=\"114\" width=\"120\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"560\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sh-101</text><rect x=\"145\" y=\"150\" width=\"210\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">data</text><text x=\"250\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a row of a data file</text><text x=\"540\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not defined</text><rect x=\"160\" y=\"190\" width=\"180\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">local</text><text x=\"250\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a script, for one request</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not defined</text><line x1=\"40\" y1=\"34\" x2=\"40\" y2=\"218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04scopes-ah)\"></line><text x=\"48\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">narrower</text><rect x=\"470\" y=\"238\" width=\"180\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sent: sh-101</text><line x1=\"605\" y1=\"140\" x2=\"605\" y2=\"236\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f04scopes-ah)\"></line><text x=\"250\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the narrowest scope that defines a name wins</text></svg>", "caption": "The same name in two scopes: the narrower one is sent, whichever was set last."}
```

So a `showId` defined in the collection as `sh-103` and in the environment as `sh-101` is sent as
`sh-101`, because the environment is narrower. Delete the environment's and the collection's
reappears. This is a feature: the collection carries a sensible default, and an environment
overrides only what differs on its server.

**A variable that exists with an empty value still wins.** An empty `token` in the environment
hides a full `token` in the collection, and the request goes out with nothing where the token
should be. Lesson 5 walks straight into this, on purpose, and shows what it looks like from the
outside.

## A name nobody defined

When no scope defines a name, Postman draws it in red in the request. If you send it anyway, it
sends the braces as they are. `{{baseUrl}}/v1/shows` is not an address, and the request fails before
it reaches any server. A tester checks the other direction too: **which names does a collection use,
and is each one defined somewhere?** Section 06 asks that of the collection you save, with one line
of grep.
