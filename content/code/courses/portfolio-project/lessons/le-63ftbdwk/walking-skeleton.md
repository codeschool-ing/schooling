---
title: A skeleton that walks
version: 1
---

There are two ways to build the same project, and only one of them finishes. The first is layer by
layer: design every screen, then write the whole API, then the database, then work out how to deploy
it. It feels thorough, and nothing runs until the last layer is done, which is usually where it stops.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two ways to build the same four layers: page, API, database and deploy. On the left, built layer by layer: the page is finished and wide, the API half done, the database a sketch and the deploy missing, so nothing works end to end. On the right, a walking skeleton: a thin slice goes through all four layers, so the smallest version works end to end from the first week.\"><defs><marker id=\"sk5-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">built layer by layer</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">a walking skeleton</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">page</text><rect x=\"90\" y=\"36\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"90\" y=\"36\" width=\"250\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">page</text><rect x=\"460\" y=\"36\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"560\" y=\"36\" width=\"50\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><rect x=\"90\" y=\"86\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"90\" y=\"86\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><rect x=\"460\" y=\"86\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"560\" y=\"86\" width=\"50\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">database</text><rect x=\"90\" y=\"136\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"90\" y=\"136\" width=\"80\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">database</text><rect x=\"460\" y=\"136\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"560\" y=\"136\" width=\"50\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deploy</text><rect x=\"90\" y=\"186\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"390\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deploy</text><rect x=\"460\" y=\"186\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"560\" y=\"186\" width=\"50\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M585 76 L585 86\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M585 126 L585 136\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M585 176 L585 186\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path></svg>", "caption": "Layer by layer, nothing runs until the last layer is done. A walking skeleton runs from the first week, and every change after that makes a working thing better."}
```

The second is a **walking skeleton**: the thinnest possible slice that goes through every layer, from
a page a person can open to the database behind it, working end to end in the first days. Everything
after that is a change to something that already runs, and a project that already runs is much
harder to abandon.

loanbook's skeleton is its first five commits:

```
ana@laptop:~/loanbook$ git log --oneline
28edce4 Take an item back
3227967 Lend an item to somebody
8623595 List the equipment from SQLite
64f0369 Serve a page with nothing on it yet
19e36eb Say what loanbook is for
```

Each commit is a slice, not a layer. *Serve a page with nothing on it yet* is a page and a server with
no data. *List the equipment from SQLite* adds the database and the API at once, and the page shows
what they return. *Lend* and *take back* each add a route, a query and a button. By the fifth commit a
teacher could, in principle, use it. Lesson 7 tags that commit `v0.1.0`.

Notice what the skeleton does not have: no tests, no styling to speak of, no error handling, no
deploy yet. Those come, but **after** something works, because each of them is easier to add to a
thing that runs than to a plan.
