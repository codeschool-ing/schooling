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

```schooling-example
{"language": "python", "file": "acl.py", "parts": [
 {"code": "# acl.py\nimport json\nfrom catalogue import Book\n\nFEED = \"\"\"[\n {\"isbn13\": \"9786555550016\", \"ttl\": \"VIDAS SECAS\", \"aut\": [\"RAMOS, Graciliano\"],\n  \"assnt\": [\"Ficção brasileira\", \"Seca\"], \"stat\": \"A\"},\n {\"isbn13\": \"9786555550023\", \"ttl\": \"GRANDE SERTÃO: VEREDAS\", \"aut\": [\"ROSA, João Guimarães\"],\n  \"assnt\": [], \"stat\": \"A\"},\n {\"isbn13\": \"9786555550031\", \"ttl\": \"IRACEMA\", \"aut\": [\"ALENCAR, José de\"],\n  \"assnt\": [\"Romantismo\"], \"stat\": \"A\"},\n {\"isbn13\": \"9786555550047\", \"ttl\": \"O GUARANI\", \"aut\": [], \"assnt\": [], \"stat\": \"D\"}\n]\"\"\"", "note": "The service's feed, as it arrives: its own field names, titles in capitals, authors as \"SURNAME, Given\", and a status letter. A real feed would come over the network; a string keeps the program runnable anywhere."},
 {"code": "\n\nclass Untranslatable(ValueError):\n    pass", "note": "A record the layer cannot turn into a `Book` raises its own error, so the catalogue never receives half a book."},
 {"code": "\n\ndef isbn_ok(digits: str) -> bool:\n    if len(digits) != 13 or not digits.isdigit():\n        return False\n    total = sum(int(d) * (1 if i % 2 == 0 else 3) for i, d in enumerate(digits))\n    return total % 10 == 0\n\n\ndef author(name: str) -> str:\n    surname, _, given = name.partition(\", \")\n    return f\"{given} {surname.title()}\" if given else name.title()\n\n\ndef title(text: str) -> str:\n    small = {\"de\", \"da\", \"do\", \"e\"}\n    words = text.lower().split()\n    return \" \".join(w if i and w in small else w[:1].upper() + w[1:] for i, w in enumerate(words))", "note": "Three small translations: the ISBN's check digit is verified, \"RAMOS, Graciliano\" becomes \"Graciliano Ramos\", and \"VIDAS SECAS\" becomes \"Vidas Secas\". Each is about their format, and each lives here and nowhere else."},
 {"code": "\n\ndef translate(record: dict) -> Book:\n    if record.get(\"stat\") != \"A\":\n        raise Untranslatable(f\"{record.get('isbn13')}: withdrawn by the service\")\n    digits = record[\"isbn13\"]\n    if not isbn_ok(digits):\n        raise Untranslatable(f\"{digits}: check digit does not match\")\n    isbn = f\"{digits[:3]}-{digits[3:5]}-{digits[5:9]}-{digits[9:12]}-{digits[12]}\"\n    return Book(isbn=isbn, title=title(record[\"ttl\"]),\n                authors=tuple(author(a) for a in record[\"aut\"]),\n                subjects=tuple(record[\"assnt\"]))", "note": "`translate` is the layer's one door. Their words go in (`ttl`, `aut`, `assnt`, `stat`), the catalogue's `Book` comes out, and a status other than `A` is refused rather than guessed at."},
 {"code": "\n\nif __name__ == \"__main__\":\n    for record in json.loads(FEED):\n        try:\n            book = translate(record)\n            print(\"in: \", book.isbn, book.citation())\n        except Untranslatable as err:\n            print(\"out:\", err)"}
]}
```

```
ana@laptop:~/patterns/ddd-strategic$ python3 acl.py
in:  978-65-5555-001-6 Graciliano Ramos. Vidas Secas.
in:  978-65-5555-002-3 João Guimarães Rosa. Grande Sertão: Veredas.
out: 9786555550031: check digit does not match
out: 9786555550047: withdrawn by the service
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
