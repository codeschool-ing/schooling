---
title: "Anticorruption layer: translating at the border"
version: 1
---

**An anticorruption layer is a piece of code at the edge of your context that turns another
model's data into your own model, so that the other model's words, shapes and habits never reach
your code.** Everything outside speaks their language; everything inside speaks yours; the layer is
the only place that knows both.

The temptation it resists is convenience. The national bibliographic service sends records with a
field called `ttl`, so the quickest code writes `record["ttl"]` wherever a title is needed: in the
search, on the desk screen, in the overdue letters. Each use is a small debt. The day the service
renames `ttl` to `titulo`, or sends titles in capitals, or adds a status that means "withdrawn",
every one of those places has to find out. **A foreign model spreads through a codebase one
convenient line at a time**, and the layer exists to stop it at the first one.

## The service's records, and ours

The service sends a feed of records like this one:

```json
{"isbn13": "9786555550016", "ttl": "VIDAS SECAS", "aut": ["RAMOS, Graciliano"],
 "assnt": ["Ficção brasileira", "Seca"], "stat": "A"}
```

The catalogue's own model is `catalogue.Book` from two sections back: an ISBN written with hyphens,
a title in normal capitalisation, authors as their names are printed on a cover, and subjects. The
layer below turns one into the other, and refuses what it cannot turn. It imports `catalogue.py`,
which must be in the same directory:

@@ex:acl@@

```
ana@laptop:~/patterns/ddd-strategic$ python3 acl.py
placeholder
```

Two records come in as proper catalogue books, with "RAMOS, Graciliano" turned into "Graciliano
Ramos" and "GRANDE SERTÃO: VEREDAS" into "Grande Sertão: Veredas". The third is refused because its
check digit is wrong, and the fourth because the service marked it withdrawn. Neither refusal
reaches the catalogue as a half-filled `Book`.

## What makes it a layer

Three properties, all visible in `acl.py`:

- it is the only code that names their fields. Search the rest of the catalogue for `ttl` and
  you find nothing. When the service changes, one file changes;
- it speaks our model on the way out. `translate` returns a `catalogue.Book`, the same class the
  rest of the catalogue already uses, and the code that calls it does not know a feed exists;
- it decides what we do not accept. A status of `D` could have been mapped to a `withdrawn`
  flag on our `Book`, and the catalogue would then have to handle withdrawn books everywhere. The
  layer chose to refuse them at the border instead, which kept a concept the catalogue does not
  need out of its model.

In a larger system the layer often has more parts: a client that fetches the feed, an *adapter*
that does the translation, and sometimes a *facade* that makes a sprawling external API look like
one simple call. Those are lesson 6's adapter and facade, put to a strategic use. The idea stays
the size of `translate`: their model in, ours out.

## When not to build one

A layer is code to write, test and keep in step with the other side. When the upstream model is
already close to yours, conforming to it is cheaper, as lending does with the payment provider.
Build the layer when the upstream will not change for you **and** its model would bend yours out of
shape. The bibliographic service passes both tests: it serves thousands of libraries, and its
capitals and abbreviations would otherwise be in every screen of the catalogue.
