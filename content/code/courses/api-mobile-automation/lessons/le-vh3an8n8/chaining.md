---
title: Chaining, one answer feeding the next request
version: 1
---

**Chaining is a script saving a value from one answer, and a later request reading it as a
variable.** Lesson 4 did it with your hands: copy the token, paste it into the environment; trust
that the order is `ord-1001`. The collection now does both in the scripts, and each takes one line.

## The token

The last two lines of the **Get token** script, after its three tests:

```js
pm.collectionVariables.set('token', body.access_token);
pm.collectionVariables.set('tokenExpires', Date.now() + (body.expires_in - 30) * 1000);
```

The first saves the token where the collection's `bearer` authorization looks for `{{token}}`, so
every request in `orders` sends it from then on. The second notes when the token stops being good,
in milliseconds since 1970, which is what `Date.now()` counts in: `expires_in` seconds from now,
less thirty seconds to spare. Section 05 is the script that reads it.

**`set` is outside the tests on purpose.** Inside a `pm.test`, a failing assertion stops the
function, and a save written after it would be skipped exactly when the answer was unusual. Outside,
the save always runs: if the token request answered `401`, `body.access_token` is `undefined`, that
is what gets saved, and the token tests above it have already said, by name, what went wrong.

## Why a collection variable

Postman can save into any scope: `pm.environment.set`, `pm.globals.set`, `pm.collectionVariables.set`,
and `pm.variables.set` for the local scope of one request. The token belongs to one run of this
collection, so the collection is where it goes. The environment is configuration you share with a
team, and a script writing into it changes values everybody using that environment sees. That is also why the
environment must not define `token` at all, as section 02 found out: a name in the narrower scope
hides the one the script wrote, whatever it holds.

## The order

The last line of **Create order** saves the address boxoffice gave the new order:

```js
pm.collectionVariables.set('orderUrl', pm.response.headers.get('location'));
```

`location` holds `/v1/orders/ord-1001` or whatever this order is called, so the three requests after
it are written `{{baseUrl}}{{orderUrl}}`, and they read, cancel and read again **the order this run
created**, whatever its number. `orderId` from lesson 4 is gone: a fixed id worked only on a
freshly started boxoffice, and only once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 710 264\" role=\"img\" aria-label=\"Five requests run in order: Get token, Create order, Read order, Cancel order and Read cancelled. Get token saves token into the collection variables, and Create order reads it as its Bearer token. Create order saves orderUrl from its location header, /v1/orders/ord-1001, and the last three requests read it as {{baseUrl}}{{orderUrl}}.\"><defs><marker id=\"f05chain-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get token</text><rect x=\"160\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Create order</text><rect x=\"300\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Read order</text><rect x=\"440\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"495\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Cancel order</text><rect x=\"580\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Read cancelled</text><line x1=\"130\" y1=\"50\" x2=\"160\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"270\" y1=\"50\" x2=\"300\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"410\" y1=\"50\" x2=\"440\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"550\" y1=\"50\" x2=\"580\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"355\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the run, in the order of the file</text><rect x=\"20\" y=\"170\" width=\"185\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"215\" y=\"170\" width=\"475\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"112\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">token</text><text x=\"452\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orderUrl = /v1/orders/ord-1001</text><text x=\"452\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">copied from the location header</text><line x1=\"75\" y1=\"70\" x2=\"75\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"81\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">set</text><line x1=\"180\" y1=\"168\" x2=\"180\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"174\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Bearer</text><line x1=\"245\" y1=\"70\" x2=\"245\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"251\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">set</text><line x1=\"355\" y1=\"168\" x2=\"355\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"495\" y1=\"168\" x2=\"495\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"635\" y1=\"168\" x2=\"635\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"425\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">{{baseUrl}}{{orderUrl}}</text><text x=\"355\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">both live in the collection variables, and a request reads only what an earlier one saved</text></svg>", "caption": "Two values saved by scripts, read by the requests after them."}
```

The price of chaining is order. **Read order means nothing on its own**: run it alone, before any
Create order, and `orderUrl` is undefined. That is acceptable inside one collection, where the order
is written down and Newman follows it. It is not acceptable between collections, or between test
files, which lesson 12 is about.
