---
title: One database or two
version: 1
---

The question this lesson opened with has an answer that surprises people who arrive from lessons 12
and 13: for a shop like Marginalia, **the vectors belong in the database it already runs.** The
reason is the copy. A separate store holds a second copy of the data, and keeping two copies in step
is work that never finishes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two designs side by side. Two systems: the application saves the text to PostgreSQL in step 1 and the vector to a separate vector store in step 2, which can fail after step 1 succeeded; a search asks the vector store for ids, then asks PostgreSQL for the texts. One database: the application sends one transaction and one query to PostgreSQL, whose articles table holds the text and the vector in the same row, beside the orders table.\"><defs><marker id=\"copiesen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"copiesen-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"copiesen-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">two systems</text><rect x=\"110\" y=\"40\" width=\"140\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">application</text><rect x=\"20\" y=\"190\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"90\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">text, orders</text><rect x=\"200\" y=\"190\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">vector store</text><text x=\"270\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">vectors</text><path d=\"M140 74 L80 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#copiesen-ah0)\"></path><path d=\"M220 74 L280 188\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#copiesen-ah1)\"></path><text x=\"100\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1. save the text</text><text x=\"262\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">2. save the vector</text><text x=\"266\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">can fail after 1</text><path d=\"M165 74 L115 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M195 74 L245 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"180\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">search: ids → fetch texts by id</text><path d=\"M392 30 L392 285\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"550\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">one database</text><rect x=\"480\" y=\"40\" width=\"140\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">application</text><path d=\"M550 74 L550 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#copiesen-ah2)\"></path><text x=\"562\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">one transaction, one query</text><rect x=\"430\" y=\"152\" width=\"240\" height=\"108\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL</text><rect x=\"450\" y=\"186\" width=\"200\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">articles: text + vector</text><rect x=\"450\" y=\"222\" width=\"200\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">orders, accounts</text></svg>", "caption": "With a separate store, a write is two writes and a search is two requests, and the second write can fail after the first. With the vector as a column, the text and its vector are written in one transaction and searched in one query."}
```

## A text and its vector change together

When an article changes, two things have to change with it: the text and the vector computed from
it. In two systems that is two writes, and the second can fail after the first has succeeded. In one
database it is one transaction. Here the script that re-embeds the refund article has a bug: it
loads WordLlama instead of the model the table was built with:

```schooling-example
{
  "language": "python",
  "file": "edit.py",
  "parts": [
    {
      "code": "import psycopg\nfrom pgvector.psycopg import register_vector\nfrom wordllama import WordLlama\n\nbody = \"We refund within two working days of the return reaching our warehouse.\"\nwl = WordLlama.load()",
      "note": "The new text of the refund article, and the model that will embed it. The bug is here: WordLlama, 256 dimensions, where the table holds all-MiniLM-L6-v2's 384."
    },
    {
      "code": "try:\n    with psycopg.connect() as conn:\n        register_vector(conn)\n        conn.execute(\"UPDATE articles SET body = %s WHERE id = 'h15'\", (body,))\n        v = wl.embed([\"When your refund arrives. \" + body], norm=True)[0]\n        conn.execute(\"UPDATE articles SET embedding = %s WHERE id = 'h15'\", (v,))\nexcept psycopg.Error as e:\n    print(type(e).__name__ + \":\", e)",
      "note": "Both updates run in one transaction, the one the `with` block opens, and an error inside the block rolls the whole of it back. The `except` prints the error instead of a traceback."
    },
    {
      "code": "with psycopg.connect() as conn:\n    print(conn.execute(\"SELECT left(body, 49) FROM articles WHERE id = 'h15'\").fetchone()[0])",
      "note": "Read the article back in a fresh connection."
    }
  ],
  "output": "ana@lab:~/emb$ python edit.py\nDataException: expected 384 dimensions, not 256\nWe refund within three working days of the return"
}
```

**The vector was refused, and the new text went with it.** The article still says *three working
days*, the old text, because both `UPDATE`s were in the same transaction and PostgreSQL rolled back
the whole of it. Nothing anywhere now holds a text whose vector describes something else. With the
vectors in a separate store, the text would have been saved, the vector write would have failed, and
the search would go on ranking the article by what it used to say, with nothing to show for it.

## What else comes free

The other arguments are the same shape: things you already have for the rest of the data, which a
second system would need again.

Joins come first. `recall.sql` scored 24 questions against 40 articles in one statement, and the
same search can join to orders, stock or permissions without the application stitching two answers
together. Backups come next: `pg_dump`, and whatever else backs the database up, already includes
the vector column, and a restore brings back the texts and their vectors from the same instant.
**Access control applies to the search like any other query**, so the row-level security that
Supabase recommends and lesson 17 builds needs no second implementation. And there is one thing to
operate: one set of credentials, one upgrade schedule, one place to look when the search is slow.

## When it stops winning

None of that is free at every size. The index has to live somewhere, and in PostgreSQL it lives on
the same machine as the orders.

**The search competes with everything else.** The HNSW build in this lesson took `8262.853 ms` for
20,000 rows, and every query reads the graph. On a database that also takes payments, a heavy vector
workload is load on the payments. Read replicas help with queries; they do not help with building.

**The extension sets the features.** The lab's 0.6.0 has no half-precision vectors and no iterative
index scans, and a hosted provider chooses which pgvector it offers. A dedicated store may have
quantisation, filterable indexes, hybrid keyword and vector search or one collection per tenant
built in, where PostgreSQL has them later or through more SQL. Lessons 12, 13 and 17 show what those
look like.

**The size outgrows one machine.** A vector store built to shard spreads one collection over many
machines as a matter of course. PostgreSQL can be made to do that, with more work.

The decision for Marginalia's 40 articles is not close: one database. The decision
for a corpus that is a large share of the database's whole size, searched far more often than
anything else is queried, is worth making again with a measurement. Lesson 18 puts numbers on the
storage side of it.
