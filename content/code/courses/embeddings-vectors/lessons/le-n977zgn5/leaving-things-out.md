---
title: Leaving things out
version: 1
---

The nearest books are not yet a list anybody should see. Three kinds of book have to come out, and
none of them is decided by similarity: what the reader has already read, what crowds the list with
one author, and what the shop cannot or will not sell. The wrong way to apply them is to take the
top five and then remove the ones that break a rule: for Caio, below, that would leave a list of
one.

## What the reader already has

The books a reader finished are the nearest of all to her own vector, because they are what it was
made from. `reader.py` already skipped them, and the program below shows where they would have
landed. It is the most basic rule in a recommender and the easiest to lose, for instance when the
list is cached and the reader finishes a book after the cache was built.

## One author taking over

Caio's list in the previous section had two books by Verne and two by Wells: four of five places
held by two authors. Each was a fair match on its own. Together they make a row that reads like a
mistake. A cap of one book per author fixes it, and so does any rule of the same shape, one per
series, one per genre, at most two from the same decade.

## The shop's own rules

Some books cannot be offered today: out of stock, not licensed in the reader's country, withdrawn.
Some should not be offered to this reader: an adult title on a child's account. **Those rules come
from data a vector does not hold**, and the code checks them against that data, outside the
embedding.

`filters.py` applies all three to Caio. The out-of-stock list is a single book written into the
program, standing in for what a real shop would read from its warehouse:

```schooling-example
{
  "language": "python",
  "file": "filters.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom books import B, books, readers, row\n\nr = readers[\"r02\"]\nv = B[[row[i] for i in r[\"finished\"]]].mean(axis=0)\nv /= np.linalg.norm(v)\nscores = B @ v",
      "note": "Caio's vector and the score of every book against it."
    },
    {
      "code": "out_of_stock = {\"b28\"}\nfinished = set(r[\"finished\"])\nauthors = set()",
      "note": "The three rules' data: a stock list, the books he finished, and the authors already on the list, empty to begin with."
    },
    {
      "code": "picked, looked = [], 0\nfor i in np.argsort(-scores):\n    b = books[i]\n    looked += 1\n    if b[\"id\"] in finished:\n        print(f\"  skip {b['id']}  finished       {b['title']}\")\n    elif b[\"id\"] in out_of_stock:\n        print(f\"  skip {b['id']}  out of stock   {b['title']}\")\n    elif b[\"author\"] in authors:\n        print(f\"  skip {b['id']}  same author    {b['title']}  ({b['author']})\")\n    else:\n        authors.add(b[\"author\"])\n        picked.append(i)\n        if len(picked) == 5:\n            break",
      "note": "Walk down the ranking from the top. A book that breaks a rule is skipped and the reason printed; one that passes is picked and its author recorded. Stop at five."
    },
    {
      "code": "print(f\"looked at {looked} of {len(books)} to find 5\")\nfor i in picked:\n    print(f\"  {scores[i]:.3f}  {books[i]['id']}  {books[i]['genre']:15} {books[i]['title']}  ({books[i]['author']})\")",
      "note": "How far down the walk went, and what it picked."
    }
  ]
}
```

```
ana@lab:~/emb$ python filters.py
  skip b13  finished       The Time Machine
  skip b14  finished       The War of the Worlds
  skip b16  finished       Twenty Thousand Leagues Under the Sea
  skip b28  out of stock   Around the World in Eighty Days
  skip b18  same author    The Invisible Man  (H. G. Wells)
looked at 10 of 60 to find 5
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
  0.359  b15  science fiction Frankenstein  (Mary Shelley)
  0.357  b25  adventure       Treasure Island  (Robert Louis Stevenson)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 740 170\" role=\"img\" aria-label=\"A sequence of five boxes for Caio's list. The catalogue's 60 books are ranked by similarity to his average. Walking down the ranking, a book is skipped if he has finished it, if it is out of stock, or if its author is already on the list. The walk stopped after 10 books, with five picked.\"><defs><marker id=\"funen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">60 books, ranked</text><text x=\"74\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">by similarity to Caio</text><path d=\"M138 70 L157 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funen-ah0)\"></path><rect x=\"159\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"223\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">finished?</text><path d=\"M223 100 L223 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funen-ah0)\"></path><text x=\"223\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">skip</text><path d=\"M287 70 L306 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funen-ah0)\"></path><rect x=\"308\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"372\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">out of stock?</text><path d=\"M372 100 L372 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funen-ah0)\"></path><text x=\"372\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">skip</text><path d=\"M436 70 L455 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funen-ah0)\"></path><rect x=\"457\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"521\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">author already listed?</text><path d=\"M521 100 L521 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funen-ah0)\"></path><text x=\"521\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">skip</text><path d=\"M585 70 L604 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funen-ah0)\"></path><rect x=\"606\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"670\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">5 picked</text><text x=\"670\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after looking at 10</text></svg>", "caption": "Filtering walks down the ranking rather than cutting it at five. Each rule removes books from the top, so the list has to look further down to fill its five places."}
```

**It looked at 10 of the 60 books to fill five places**, and the skipped lines say why each of
the other five went. Caio's three finished books ranked at the very top of his own list, *Around the
World in Eighty Days* was out of stock, and *The Invisible Man* was a second Wells. In
their places came *Frankenstein* at 0.359 and *Treasure Island* at 0.357, further down the ranking
and still science fiction and adventure.

## Filter while you walk, not after you cut

**The loop walks down the full ranking and stops when it has five**; it never cuts the ranking
first. With 60 books that costs nothing, since every book has a score already. With a million books and an
index that returns only the nearest 50, it matters: if the rules remove 46 of those 50, the reader
gets four recommendations, and asking the index for more is the only fix. Lesson 17 meets exactly
this problem in vector databases, where a filter applied after the search returns fewer results
than asked for, and shows the ways around it.
