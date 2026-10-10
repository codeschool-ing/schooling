---
title: What the engine does to a word
version: 1
---

Feed the catalogue into the index. The feeder creates the index from `index.json` the first time, then
sends every product in one bulk request:

```
ana@vm:~/lab/search$ $R feed.py
created index products
fed 24 products
```

Before a word is stored, it goes through the index's **analyser**. The `_analyze` endpoint shows what it
does to a piece of text:

```
ana@vm:~/lab/search$ curl -s 'localhost:9200/products/_analyze?filter_path=tokens.token' -H 'Content-Type: application/json' -d '{"field": "name", "text": "Cafés torrados em grãos"}'; echo
{"tokens":[{"token":"caf"},{"token":"torr"},{"token":"em"},{"token":"gra"}]}
```

`Cafés torrados em grãos` became four terms: `caf`, `torr`, `em`, `gra`. The tokenizer split the text into
words; `lowercase` and `asciifolding` turned `Cafés` into `cafes` and `grãos` into `graos`; the Brazilian
stemmer cut each word to a stem, so `cafés`, `café` and `cafe` all become `caf`, and `torrado`, `torrada`
and `torrados` all become `torr`. The same analyser runs on what the customer types, so `cafe torrado`
and `Cafés torrados` are looked up as the same two terms.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"An inverted index. On the left, three products: 1 Café torrado em grãos, 2 Café moído tradicional, 22 Farinha de mandioca. In the middle, the analyser turns each name into terms: caf, torr, gra, moid, tradicional, farinh, mandioc. On the right, each term points to the products that contain it: caf to 1 and 2, torr to 1, mandioc to 22.\"><defs><marker id=\"l17-inverted-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1  Café torrado em grãos</text><rect x=\"30\" y=\"100\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2  Café moído tradicional</text><rect x=\"30\" y=\"160\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">22  Farinha de mandioca</text><text x=\"390\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">analyser</text><path d=\"M252 120 L318 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-inverted-ah-phosphor)\"></path><rect x=\"320\" y=\"40\" width=\"140\" height=\"160\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lower-case</text><text x=\"390\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">remove accents</text><text x=\"390\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stem</text><path d=\"M462 120 L518 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-inverted-ah-phosphor)\"></path><rect x=\"520\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">caf</text><text x=\"612\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 1, 2</text><rect x=\"520\" y=\"74\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">torr</text><text x=\"612\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 1</text><rect x=\"520\" y=\"108\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">gra</text><text x=\"612\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 1</text><rect x=\"520\" y=\"142\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">moid</text><text x=\"612\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 2</text><rect x=\"520\" y=\"176\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">mandioc</text><text x=\"612\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 22</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">search: analyse the query the same way, then look the terms up</text></svg>", "caption": "An inverted index maps each term to the documents containing it, the way the index at the back of a book maps a word to its pages."}
```

Those terms go into an **inverted index**: for each term, the list of documents that contain it, and
where. It is inverted relative to the table, which goes from a document to its words; the index goes from
a word to its documents, like the index at the back of a book. A search for two terms reads two lists and
combines them, and never looks at a document that contains neither.

The analyser is the decision that matters most and the one that is hardest to change: it is applied when
documents are written, so changing it means **reindexing everything**. That is why `index.json` is a file
of its own, reviewed like code, and why every serious search deployment has a way to build a new index
beside the old one and switch to it, which lesson 13 would recognise as rebuilding a read model.
