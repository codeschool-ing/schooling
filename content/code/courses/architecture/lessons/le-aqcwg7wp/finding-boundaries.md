---
title: Where to draw the line
version: 1
---

The tempting cut is by noun: a product service, a customer service, an order service, one per table.
It looks tidy on a diagram and it is usually wrong, because **a noun means different things to
different parts of the business**, and a service built around the noun has to hold all of its
meanings at once.

Ask three parts of Quitanda what a product is:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three bounded contexts side by side: catalogue, stock and delivery. Each holds its own model of a product. In the catalogue a product has a name, a photo and a price. In stock it has a count of units and a shelf. In delivery it has a weight and whether it must travel cold. The only thing the three share is the identifier, sku.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"30\" width=\"200\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"130\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">catalogue</text><text x=\"130\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">product</text><rect x=\"60\" y=\"88\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sku</text><rect x=\"60\" y=\"114\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">name</text><rect x=\"60\" y=\"140\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">photo</text><rect x=\"60\" y=\"166\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">price_cents</text><rect x=\"260\" y=\"30\" width=\"200\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">stock</text><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">product</text><rect x=\"290\" y=\"88\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sku</text><rect x=\"290\" y=\"114\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">units</text><rect x=\"290\" y=\"140\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf</text><rect x=\"290\" y=\"166\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">reorder_at</text><rect x=\"490\" y=\"30\" width=\"200\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"590\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">delivery</text><text x=\"590\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">product</text><rect x=\"520\" y=\"88\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sku</text><rect x=\"520\" y=\"114\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">weight_g</text><rect x=\"520\" y=\"140\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cold_chain</text><rect x=\"520\" y=\"166\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fragile</text><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">only the sku crosses a boundary</text></svg>", "caption": "One word, three models. A boundary drawn around each meaning lets each context change its model without asking the other two; what crosses the line is only the identifier."}
```

To the catalogue, a product is a name, a photo and a price. To stock, it is a count and a shelf. To
delivery, it is a weight and whether it has to travel cold. A single "product service" would carry
all of that, and every change to any of the three meanings would be a change to it. Three services,
each owning its own meaning, can change independently, and **only the identifier crosses the
line**.

## Bounded contexts

Eric Evans gave this a name in *Domain-Driven Design*, in 2003: a **bounded context** is the area
inside which a word has one precise meaning and one model. Inside the stock context, "product"
means the count on the shelf and nothing else. A boundary between services that follows the
boundaries between contexts is one the business itself already keeps, and it tends to stay put
when the product changes.

Three questions help find them:

| question | a sign of a boundary |
| --- | --- |
| who in the business talks about this, and in what words? | a different group of people using the same word differently |
| what changes together? | two things that always change in the same pull request belong together |
| what must be consistent at the same instant? | data that must never disagree, even for a second, belongs in one transaction, so in one service |

The third question is the one people skip. If the order and the stock must never disagree, a
boundary between them means paying for the disagreement in code: lesson 14, the saga, is that code.
Sometimes it is worth it. It should never be a surprise.

## Conway's law

Melvin Conway observed in 1968 that organisations design systems whose structure copies their own
communication structure. A company with three teams tends to build a system in three parts, wherever
the natural boundaries of the problem lie. **The boundary between services and the boundary between
teams end up as the same line**, so the honest version of the question is "which team will own
this?".

The **inverse Conway manoeuvre** uses the law on purpose: arrange the teams the way you want the
system to be divided, and let the system follow. Quitanda's stock team of two, with its own release
schedule, is exactly the shape that makes a stock service the right cut.

## The signs of a wrong line

- Two services that call each other for nearly every request, in both directions.
- A change that needs a coordinated release of both sides.
- One service that needs the other's data so often that it keeps a copy and the copies disagree.
- A transaction that has to span both, which neither can give.

Each sign means the line cuts through something that belongs together. Moving it is expensive,
which is the reason lesson 1 advised drawing it inside a monolith first.
