---
title: Bridge tables, and the weight in them
version: 1
---

`bridge_book_author` is a **bridge table**: it sits between a fact table and a dimension, and turns one
key on the fact row into several rows of the dimension. Its build is short:

```sql
CREATE TABLE dim_author AS
SELECT row_number() OVER (ORDER BY author_id) AS author_key, author_id, name AS author_name,
       country
FROM staging.authors;

-- A book can have several authors, so the link is a table of its own. The
-- weight divides a book's sales between them and adds up to 1 per book.
CREATE TABLE bridge_book_author AS
SELECT b.book_key, a.author_key, ba.position,
       1.0 / count(*) OVER (PARTITION BY ba.book_id) AS weight
FROM staging.book_authors ba
JOIN dim_book b   ON b.book_id = ba.book_id
JOIN dim_author a ON a.author_id = ba.author_id;
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"fact_sales points at one book with book_key. The bridge table bridge_book_author has three rows for that book, one per author, each with weight one third. Each bridge row points at one author in dim_author. A sale reaches three authors; with the weight, each gets a third of it, and the thirds add back up to the sale.\"><defs><marker id=\"ah-bridge\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"95\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">fact_sales</text><text x=\"95\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">book_key · net_cents</text><line x1=\"170\" y1=\"120\" x2=\"230\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-bridge)\"></line><text x=\"330\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">bridge_book_author</text><rect x=\"235\" y=\"44\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">book_key · author_key</text><text x=\"245\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">weight 0.333…</text><line x1=\"425\" y1=\"65\" x2=\"480\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-bridge)\"></line><rect x=\"485\" y=\"44\" width=\"215\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dim_author</text><text x=\"495\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Quentin Lindqvist</text><rect x=\"235\" y=\"102\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">book_key · author_key</text><text x=\"245\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">weight 0.333…</text><line x1=\"425\" y1=\"123\" x2=\"480\" y2=\"123\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-bridge)\"></line><rect x=\"485\" y=\"102\" width=\"215\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dim_author</text><text x=\"495\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Vera Grieg</text><rect x=\"235\" y=\"160\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">book_key · author_key</text><text x=\"245\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">weight 0.333…</text><line x1=\"425\" y1=\"181\" x2=\"480\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-bridge)\"></line><rect x=\"485\" y=\"160\" width=\"215\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dim_author</text><text x=\"495\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tomás Paiva Bergman</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the three weights of a book add up to 1</text></svg>", "caption": "A bridge table turns one book on a sale into its authors; the weight splits the sale among them."}
```

The `weight` column divides each book among its authors: one third each for a book with three, and
the weights of every book add up to 1. Multiplying a sale by the weight before summing gives each
author a share, and the shares add back up to the sale. That is why the weighted total in the
previous section matched what the shop sold.

So which is right, weighted or not? **Both, for different questions.** Here are the top five authors:

```sql
SELECT a.author_name,
       round(sum(f.net_cents) / 100, 2)             AS impact_brl,
       round(sum(f.net_cents * ba.weight) / 100, 2) AS weighted_brl
FROM fact_sales f
JOIN bridge_book_author ba USING (book_key)
JOIN dim_author a USING (author_key)
GROUP BY ALL
ORDER BY impact_brl DESC
LIMIT 5;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < top-authors.sql
┌───────────────────────┬────────────┬──────────────┐
│      author_name      │ impact_brl │ weighted_brl │
│        varchar        │   double   │    double    │
├───────────────────────┼────────────┼──────────────┤
│ Petra Dahl Torres     │ 3098982.11 │   3092387.91 │
│ Ada Sandberg          │ 2818705.13 │   2804291.94 │
│ Olga Fontes           │ 2638780.29 │   2638780.29 │
│ Rui Ibsen Orvalho     │ 2066709.72 │   2062143.18 │
│ Klara Bergman Lacerda │ 2053136.15 │   2053136.15 │
└───────────────────────┴────────────┴──────────────┘
```

- **The weighted column is an allocation.** It answers "how much revenue should we attribute to each
  author", for royalties, for targets, for anything that has to add up to the shop's total. Petra Dahl
  Torres gets R$ 3,092,387.91, the author's share of every book with that name on it.
- **The unweighted column is the impact.** It answers "how much did the books this author worked on
  sell", for deciding whom to invite to an event or which backlist to promote. Petra Dahl Torres is on
  R$ 3,098,982.11 of sales. That is a true statement about the author, and the five numbers in that
  column do not add up to anything.

Olga Fontes and Klara Bergman Lacerda have the same number in both columns, because none of their
books has a co-author.

**The rule for reports**: say which one it is. A table headed "revenue by author" with unweighted
numbers in it will be totalled by somebody, and the total will be sixteen million reais too high. Lesson
12's dictionary records which columns are allocations and which are impacts, so the report tool can
refuse to total the second.

The same structure turns up wherever a fact meets a set: a patient with several diagnoses, a bank
account with several holders, an incident assigned to several teams. The bridge has a row per pair,
and a weight when the shares have to add up.
