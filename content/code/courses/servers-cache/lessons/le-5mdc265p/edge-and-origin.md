---
title: Edge and origin
version: 1
---

A server in São Paulo answers a visitor in São Paulo in a few milliseconds and a visitor in Lisbon in
well over a hundred. Light in fibre takes that long to cross an ocean and back, and a page
needs several round trips before anything is drawn. **No configuration of the server changes that
distance.** What changes it is answering from somewhere closer.

A **content delivery network**, a CDN, is a company that runs caches in hundreds of places, called
**points of presence** or **edges**, and puts them between your visitors and your server, which in its
vocabulary becomes the **origin**. A visitor in Lisbon is sent to the edge in Lisbon. If that edge has a
fresh copy, the answer never crosses the ocean; if not, the edge fetches it from the origin once and
keeps it for everybody else in Lisbon.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" aria-label=\"Visitors in Lisbon and in Recife each reach a nearby edge with a short line. Only on a miss does an edge fetch from the origin in São Paulo, over a long line; hits never cross that distance.\"><defs><marker id=\"fed-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"130\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">visitors, Lisbon</text><rect x=\"20\" y=\"160\" width=\"130\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">visitors, Recife</text><rect x=\"220\" y=\"30\" width=\"150\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">edge, Lisbon</text><rect x=\"220\" y=\"160\" width=\"150\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">edge, Recife</text><rect x=\"530\" y=\"95\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">origin</text><text x=\"605.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">São Paulo</text><line x1=\"150\" y1=\"52\" x2=\"218\" y2=\"52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fed-ah)\" marker-start=\"url(#fed-ah)\"></line><line x1=\"150\" y1=\"182\" x2=\"218\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fed-ah)\" marker-start=\"url(#fed-ah)\"></line><text x=\"184\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">few ms</text><text x=\"184\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">few ms</text><path d=\"M 370 52 C 450 52, 470 110, 528 115\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fed-ah)\"></path><path d=\"M 370 182 C 450 182, 470 130, 528 128\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fed-ah)\"></path><text x=\"455\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">only on a miss, ~100+ ms</text><text x=\"455\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">only on a miss</text></svg>", "caption": "Each visitor reaches the nearest edge. The long trip to the origin is paid once per copy, not once per visitor."}
```

Two mechanisms send each visitor to a nearby edge, and both are invisible to the visitor. With **DNS**,
the CDN's name servers answer the site's name with the address of an edge close to whoever asked. With
**anycast**, many edges announce the same address, and the internet's routing delivers each packet to
the nearest of them. Either way the site's name points at the CDN, usually with a `CNAME` record, and
only the CDN knows where the origin is.

Everything lesson 5 said about shared caches applies to an edge, because an edge is one: it obeys
`Cache-Control`, `s-maxage` is addressed to it, `private` keeps it out, and its key decides who gets
which copy. What is new is that **you do not run it**. Its configuration is a web page or an API, its
logs arrive late, and purging a copy is a request to somebody else's machines in a hundred cities. This
lesson builds one small edge on your server, so that every one of those things can be seen working,
and the last section maps them onto the commercial ones.
