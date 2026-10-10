---
title: Why not `LIKE`
version: 1
---

The first search box in most applications is a `LIKE` query: `WHERE name ILIKE '%' || :words || '%'`.
It finds rows whose text contains the letters typed, and for a back-office screen searched by people who
know the exact names it is enough. For customers it fails in ways they notice at once:

| the customer types | what `ILIKE` does | what they expected |
| --- | --- | --- |
| `cafe` | misses every `Café`, because `e` is not `é` | the coffee |
| `cafés` | misses `Café`, because the plural has an extra letter | the coffee |
| `café torrado` | finds only names with those two words next to each other, in that order | anything with both |
| `cafe torado` | nothing; one letter wrong is no match | the coffee, with a "did you mean" |
| `café` | forty rows, in whatever order the table returns them | the most relevant first |

It is also slow at scale. A pattern that starts with `%` cannot use an ordinary index, so every search
reads every row: lesson 16's busy database, on the page customers use most.

A **search engine** is built for the other column of that table. It **analyses** text, both when it
stores it and when it searches, so that `cafés`, `Café` and `cafe` become the same term. It keeps an
**inverted index**, from each term to the documents that contain it, so a search reads only the
documents that match. It **ranks** them by relevance. It tolerates **typos**. And it counts results by
category, price band or brand on the same request, the filters beside the results, called **facets**.

PostgreSQL itself goes part of the way, with `tsvector`, `to_tsquery` and the `unaccent` and `pg_trgm`
extensions, and for a small catalogue that may be all a shop needs. This lesson uses a dedicated engine,
because that is what the larger shops use and because seeing it run explains what the database's
features are imitating.
