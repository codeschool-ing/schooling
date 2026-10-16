---
title: Two writers, one order
version: 1
---

A command loads the order, decides, and appends. Between the load and the append, somebody else may
have appended: a customer adds coffee on the phone while the same basket on the laptop adds tea. In an
ordinary table, the second `UPDATE` would quietly overwrite the first, which is lesson 9's lost write
inside one database.

Event sourcing has a natural answer. Every append says **which version it expects to be writing**, and
`UNIQUE (stream, version)` refuses a second version 2. Place o-3, then send two commands half a second apart,
each thinking for two seconds between loading and appending:

```
ana@vm:~/lab/events$ $O place o-3
o-3 v1: OrderPlaced
ana@vm:~/lab/events$ $O add o-3 tea 2 --think & sleep 0.5; $O add o-3 coffee 1 --think; wait
o-3 v2: ItemAdded {"product": "tea", "units": 2}
o-3: changed by somebody else since version 1; load it and try again

ana@vm:~/lab/events$ $O show o-3
o-3 at v2: open, tea x2
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two writers and one order. Both load o-3 at version 1. The first appends version 2 and succeeds. The second also tries to append version 2, the unique constraint refuses it, and it is told the order changed since version 1.\"><defs><marker id=\"l13-conflict-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-conflict-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-conflict-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"35\" y=\"26\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">writer A</text><path d=\"M110 56 L110 226\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"285\" y=\"26\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">events of o-3</text><path d=\"M360 56 L360 226\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"535\" y=\"26\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">writer B</text><path d=\"M610 56 L610 226\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M357 80 L113 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-conflict-ah-paper-dim)\"></path><text x=\"235\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">load: v1</text><path d=\"M363 80 L607 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-conflict-ah-paper-dim)\"></path><text x=\"485\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">load: v1</text><path d=\"M113 130 L357 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-conflict-ah-phosphor)\"></path><text x=\"235\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">append v2</text><text x=\"368\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">v2 written</text><path d=\"M607 180 L363 180\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-conflict-ah-amber)\"></path><text x=\"485\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">append v2</text><text x=\"485\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refused: changed since v1</text></svg>", "caption": "Optimistic concurrency: each append says which version it expected, and the second writer to arrive is refused instead of silently overwriting the first."}
```

Both loaded version 1. The tea arrived first and became version 2. The coffee's append also claimed
version 2, the constraint refused it, and the command said so instead of overwriting anything. This is
**optimistic concurrency**: nothing is locked while a person or a program thinks, and the rare collision
is detected at the end and handed back. The usual response is to load the order again, check that the
command still makes sense against the new state, and try once more, which here would succeed and add the
coffee as version 3.

The stream is the unit of consistency. Within one order, every change is checked against all the
previous ones; **across orders, nothing is**, because no command loads two streams. A rule that spans
several streams, such as "never sell more coffee than is in stock" when every order is its own stream,
needs either a stream that owns the rule (a stock stream that every order must append to) or lesson 14's
saga.
