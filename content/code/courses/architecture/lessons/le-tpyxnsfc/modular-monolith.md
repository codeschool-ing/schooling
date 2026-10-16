---
title: The modular monolith
version: 1
---

A monolith goes wrong in a recognisable way. Any function can call any other, any query can read
any table, and after a few years every part of the program depends on every other part. Brian
Foote and Joseph Yoder named the result in 1997: **a big ball of mud**, a system with no shape that
anybody can change without fear. The usual conclusion is that the cure is to split it into
services. **The ball of mud is a failure of boundaries, not of deployment**, and a program can have
strong boundaries inside one process.

That is a **modular monolith**: one deployable unit, divided into modules that each own a piece of
the domain and its data, and that reach each other only through a small public surface.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Four modules inside one process, each drawn as a box with a small public door on its edge. Orders reaches stock and payments through their doors, drawn as solid arrows. A dashed arrow from orders goes straight into the stock module&#x27;s table and is crossed out as forbidden.\"><defs><marker id=\"l1-modular-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l1-modular-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"26\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">one process, one deploy</text><rect x=\"40\" y=\"60\" width=\"190\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">orders</text><text x=\"135\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">place()</text><rect x=\"300\" y=\"60\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">stock</text><rect x=\"310\" y=\"92\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">take(sku, n)</text><rect x=\"600\" y=\"72\" width=\"90\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its table</text><path d=\"M552 95 L598 95\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"300\" y=\"160\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">payments</text><rect x=\"310\" y=\"192\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">charge(…)</text><path d=\"M232 107 L308 107\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-modular-ah-phosphor)\"></path><path d=\"M232 207 L308 207\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-modular-ah-phosphor)\"></path><path d=\"M150 58 C 150 26, 645 22, 645 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l1-modular-ah-amber)\"></path><text x=\"400\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">forbidden: straight to the table</text></svg>", "caption": "A modular monolith is still one deploy. What it adds is a rule: a module is entered through its public functions, never through its tables."}
```

Quitanda's `app.py` already has the four modules, and it already breaks the rule once.
`catalogue_list` joins `products` with `stock`, so the catalogue reads a table that belongs to the
stock module. It works, and it means the stock table can no longer change shape without the
catalogue changing with it. In a modular monolith the catalogue asks the stock module for the
units, through a function stock publishes, and never sees the table.

## The three rules

| rule | what it prevents |
| --- | --- |
| each module owns its tables, and only its code reads or writes them | a change of schema rippling through code nobody knew depended on it |
| a module is used only through the functions it declares public | callers coupling themselves to its internals |
| dependencies between modules point one way, with no cycles | two modules that can only ever change together, which is one module |

**A rule nobody checks is a habit, and habits erode under deadlines.** The rules are enforced by a
tool that fails the build: `import-linter` for Python, ArchUnit for Java, the module system Java has
had since version 9, `packwerk` for Ruby, Go's `internal/` directories, which the Go toolchain refuses
to let code outside their parent directory import. The repository this course is stored in does the same thing:
a test reads the import graph of its Go packages and fails when one module imports another it is
not allowed to.

## Why bother, if it is one deploy anyway

Because the boundaries are the expensive part of a split, and they are cheaper to find inside one
process. Moving a boundary in a modular monolith is a refactoring with a compiler and a test suite
watching. Moving it between two services is a change to two deployments, an API and a migration of
data, done while both are running.

So a modular monolith is two things at once: a good shape to stay in, and the best starting point
if the day comes to split. **A module that already owns its data and has a public surface is a
service waiting for a network**, and lesson 15 shows how one is moved out of a running system. A
ball of mud first has to be turned into modules, and that is most of the work.
