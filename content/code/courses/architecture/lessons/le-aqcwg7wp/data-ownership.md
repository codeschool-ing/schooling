---
title: A database per service
version: 1
---

The shortcut that undoes a split is the shared database. Two services, one database, each reading
the other's tables directly because it is faster than calling an API. It works on the first day, and
from then on **every column of every shared table is part of the contract between the services**,
a contract nobody wrote down and nobody can version.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two drawings. On the left, the shop and the stock service both read and write one shared database, drawn with crossing arrows into the same tables. On the right, each service has its own database, and the shop gets stock data only by calling the stock service&#x27;s API.\"><defs><marker id=\"l2-ownership-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l2-ownership-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"340\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"370\" y=\"10\" width=\"340\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">shared database</text><text x=\"540\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">a database per service</text><rect x=\"40\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop</text><rect x=\"210\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stock</text><rect x=\"60\" y=\"170\" width=\"240\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one database</text><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stock, orders, products</text><path d=\"M95 92 L230 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-amber)\"></path><path d=\"M265 92 L130 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-amber)\"></path><rect x=\"400\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop</text><rect x=\"570\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stock</text><rect x=\"400\" y=\"170\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.db</text><rect x=\"570\" y=\"170\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stock.db</text><path d=\"M455 92 L455 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-phosphor)\"></path><path d=\"M625 92 L625 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-phosphor)\"></path><path d=\"M512 70 L568 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-phosphor)\"></path><text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">API</text></svg>", "caption": "A shared database couples the two services through every column of every table they both touch. Owning the data puts the coupling in one place, the API, where it can be versioned."}
```

With a shared table, the stock team cannot rename a column, split a table or change what `units`
means without finding every query in every other service that reads it and releasing them all
together. That is exactly the coordinated release the split was meant to end. **Owning the data is
what makes independent deployment possible**; without it, the services are independent only on the
diagram.

In the lab the rule is physical: `stock.db` is in the `stock-data` volume, mounted only into the
stock container, so the shop has no way to open it. In production the same rule is usually kept by
giving each service its own database user, with no grant on the other's schema, or its own database
server.

## When another service needs your data

The shop needs the stock counts to show the catalogue. There are three ways to give it them, and
they trade freshness against independence:

| way | how fresh | what the shop depends on |
| --- | --- | --- |
| **ask**: call the stock service's API when the data is needed | as fresh as it gets | the stock service being up and fast, on every request |
| **listen**: the stock service publishes an event each time a count changes, and the shop keeps its own copy | a little behind, by however long an event takes | the events arriving, in order, once; lessons 5 to 7 |
| **copy in bulk**: a read-only replica or a nightly export | behind by up to the copy's interval | the copy job, and a schema it has to keep in step with |

Quitanda's shop asks, which is the simplest and fine at this size. Lesson 9 shows what a customer
sees when the shop listens instead and its copy is a moment behind.

## What it costs

Two databases are two things to back up, upgrade and watch. A report that needs data from both, say
"units sold per product, with its price", is no longer one `JOIN`: it has to call two APIs or read
from somewhere that holds both, which is often a separate store built for reporting. And there is
the transaction that no longer exists, from the previous section. **The cost is real and it is the
price of the independence**; a team that is not using the independence should not be paying it.
