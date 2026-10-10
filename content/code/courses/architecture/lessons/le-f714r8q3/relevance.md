---
title: Relevance, typos and facets
version: 1
---

Search for roasted coffee, the way a customer would type it:

```
ana@vm:~/lab/search$ $R search.py café torrado
5 matches
  11.10  Café torrado em grãos
   5.67  Café descafeinado
   4.83  Café moído tradicional
   4.83  Café em cápsulas
   1.60  Farinha de mandioca
categories: café (4), mercearia (1)
```

Five products, in order, each with a **score**, and a count by category beside them. The score is
**BM25**, the ranking function every engine in this lesson uses by default. Three things raise it: the
term appears in the field (more often counts, with diminishing returns), the term is **rare** in that field across
the catalogue (among names, `torr` is in one and `caf` in four, so `torr` is worth more), and the field is
**short** (a match in a five-word name says more than one in a long description). `name^3` in
`search.py` adds a fourth: a match in the name counts three times as much as one in the description.
That is why `Café torrado em grãos` is first, with both words in its name, the other coffees follow on
`café`, and `Farinha de mandioca` comes last, matched only by `torrada` in its description.

The database, asked the obvious way, does worse on the same words:

```
ana@vm:~/lab/search$ docker compose exec -T db psql -U postgres -c "SELECT name FROM products WHERE name ILIKE '%cafe torrado%'" -c "SELECT name FROM products WHERE name ILIKE '%café torrado%'"
 name 
------
(0 rows)

         name          
-----------------------
 Café torrado em grãos
(1 row)
```

Without the accent, nothing; with it, one row, because only one name has the two words side by side.

Now a customer in a hurry types `cafe torado`. The accent no longer matters, but `torado` is not a word
in the index:

```
ana@vm:~/lab/search$ $R search.py cafe torado
4 matches
   5.67  Café descafeinado
   4.83  Café moído tradicional
   4.83  Café em cápsulas
   4.20  Café torrado em grãos
categories: café (4)
```

The coffees are still found, through `cafe`, but the one the customer wanted has dropped to fourth,
because nothing matched `torado`. `--fuzzy` lets each term be up to two edits away from a term in the
index, Levenshtein distance, scaled to the word's length:

```
ana@vm:~/lab/search$ $R search.py cafe torado --fuzzy
5 matches
   8.80  Café torrado em grãos
   5.67  Café descafeinado
   4.83  Café moído tradicional
   4.83  Café em cápsulas
   1.07  Farinha de mandioca
categories: café (4), mercearia (1)
```

`torado` reached `torr` again, and the roasted coffee is back on top. Fuzziness has a usual price, more
results that are a little wrong, which BM25 keeps below the right ones. The `categories` line is the
facet: counts the shop shows beside the results as filters, computed in the same request.
