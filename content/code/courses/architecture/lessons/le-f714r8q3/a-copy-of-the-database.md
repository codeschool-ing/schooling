---
title: The index is a copy
version: 1
---

The search index is never the source of truth. Prices, stock and descriptions are decided in the shop's
database, and the index holds a copy shaped for searching. Lesson 9 has a word for that, and it applies
here exactly.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The database holds the products and is the source of truth. A feeder reads the rows changed since its last run and sends them to the search index in bulk. The search box reads only from the index. Between a change in the database and the next run of the feeder, plus up to one second of refresh, the index shows the old version.\"><defs><marker id=\"l17-copy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-copy-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"80\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">PostgreSQL</text><text x=\"105\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source of truth</text><rect x=\"280\" y=\"80\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">feed.py</text><text x=\"355\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">changed rows</text><rect x=\"530\" y=\"80\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">OpenSearch</text><text x=\"610\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a copy</text><path d=\"M182 110 L278 110\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-copy-ah-amber)\"></path><path d=\"M432 110 L528 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-copy-ah-phosphor)\"></path><text x=\"480\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">_bulk</text><rect x=\"530\" y=\"170\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">search.py</text><path d=\"M610 168 L610 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-copy-ah-phosphor)\"></path><text x=\"230\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lag: feeder interval + up to 1 s refresh</text></svg>", "caption": "The index is a copy fed from the database. It lags by the feeder's interval plus the engine's refresh, and it can always be rebuilt from the source."}
```

Add a product to the database, then search for it before the feeder has run:

```
ana@vm:~/lab/search$ docker compose exec -T db psql -U postgres -c "INSERT INTO products (id, name, category, description, cents) VALUES (25, 'Café gelado em lata', 'café', 'Café com leite gelado, lata de 250 ml.', 690)"
INSERT 0 1
ana@vm:~/lab/search$ $R search.py gelado
1 match
   2.64  Chá mate tostado
categories: chá (1)
```

The database has the iced coffee; the search box has never heard of it. Run the feeder, and search
straight away:

```
ana@vm:~/lab/search$ $R feed.py; $R search.py gelado; sleep 5; $R search.py gelado
fed 1 products
1 match
   2.64  Chá mate tostado
categories: chá (1)
2 matches
   7.07  Café gelado em lata
   2.21  Chá mate tostado
categories: café (1), chá (1)
```

The feeder sent it, and the first search **still did not find it**. Five seconds later it did. That is
the engine's **refresh**: new documents are written into an in-memory buffer and become searchable when
the buffer is turned into a new segment, by default once a second; the lab's index waits five, so that
the gap is wide enough to see. Search engines call themselves **near
real-time** for this reason. A bulk load can turn refresh off to go faster, and a test that indexes and
searches in the same breath has to ask for a refresh or wait for one.

So the index lags the database by **the feeder's interval plus the refresh**, a second by default. The lab's feeder runs
when asked. In production it is one of three things, from simplest to most current:

| how the index is fed | lag | what it costs |
| --- | --- | --- |
| a job every few minutes, reading rows changed since the last run, as the lab does | minutes | an `updated_at` that every write must set; deletes need a soft-delete flag to be seen |
| events from the application, through an outbox (lesson 7) | seconds | every change has to publish an event |
| change data capture from the database's log, for example Debezium into Kafka | seconds | another moving part, but no change to the application |

And because the index is a copy, it can always be **rebuilt from the source**: create a new index,
feed everything into it, and point the search box at it. Engines support this with **aliases**, a name
the application uses that can be switched from the old index to the new one in one step.
