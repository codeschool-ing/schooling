---
title: More like this
version: 1
---

Under every book on Marginalia's site there is room for a row headed *more like this*. The common
picture of what fills it is a clever model trained on millions of shoppers. The simplest version
needs none of that: it is the search from lesson 3 with a book in place of the question. Embed every
book once, and the books nearest to the one on the page are the row.

That is called **item-to-item**, or **content-based**, recommendation: it uses what the books are,
not who bought them. The sixty books in `data/books.jsonl` each carry a title, an author, a genre
and a short blurb, and a small module embeds them once for every program in this lesson:

```schooling-example
{
  "language": "python",
  "file": "books.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nfrom minilm import embed",
      "note": "`embed` runs all-MiniLM-L6-v2, as in every lesson so far."
    },
    {
      "code": "books = [json.loads(line) for line in open(\"data/books.jsonl\")]\nreaders = {r[\"reader\"]: r for r in map(json.loads, open(\"data/readers.jsonl\"))}\nrow = {b[\"id\"]: i for i, b in enumerate(books)}",
      "note": "Read the sixty books and the twelve readers. `row` maps a book's id to its position, which is also its row in the matrix of vectors."
    },
    {
      "code": "if not os.path.exists(\"books.npy\"):\n    np.save(\"books.npy\", embed([b[\"title\"] + \". \" + b[\"blurb\"] for b in books]))\nB = np.load(\"books.npy\")",
      "note": "Embed each book as its title and blurb, once; later runs load `books.npy` instead of running the model."
    },
    {
      "code": "def show(scores, skip=(), n=5):\n    for i in np.argsort(-scores):\n        b = books[i]\n        if b[\"id\"] in skip:\n            continue\n        print(f\"  {scores[i]:.3f}  {b['id']}  {b['genre']:15} {b['title']}  ({b['author']})\")\n        n -= 1\n        if n == 0:\n            break",
      "note": "`show` prints the top `n` books by score, skipping any id in `skip`. Every program in the lesson prints its lists through it."
    }
  ]
}
```

## The row under a book

```python
import sys
from books import B, books, row, show

b = books[row[sys.argv[1]]]
print(b["id"], b["title"], "-", b["genre"])
show(B @ B[row[b["id"]]], skip={b["id"]})
```

```
ana@lab:~/emb$ python like.py b07
b07 The Hound of the Baskervilles - mystery
  0.444  b04  romance         Wuthering Heights  (Emily Brontë)
  0.411  b55  mystery         The Adventures of Sherlock Holmes  (Arthur Conan Doyle)
  0.397  b11  mystery         The Mysterious Affair at Styles  (Agatha Christie)
  0.383  b30  adventure       The Call of the Wild  (Jack London)
  0.376  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
ana@lab:~/emb$ python like.py b13
b13 The Time Machine - science fiction
  0.395  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.348  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.346  b18  science fiction The Invisible Man  (H. G. Wells)
  0.328  b15  science fiction Frankenstein  (Mary Shelley)
  0.308  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
```

Read the first list before trusting it. Under **The Hound of the Baskervilles**, a detective
story, the nearest book is **Wuthering Heights**, a romance, at 0.444, ahead of the Sherlock Holmes
stories at 0.411. The two blurbs show why:

```
ana@lab:~/emb$ grep -E "\"(b04|b07)\"" data/books.jsonl
{"id": "b04", "title": "Wuthering Heights", "author": "Emily Brontë", "year": 1847, "genre": "romance", "blurb": "A foundling and the daughter of the house share a wild love on the moors that turns to revenge across two generations."}
{"id": "b07", "title": "The Hound of the Baskervilles", "author": "Arthur Conan Doyle", "year": 1902, "genre": "mystery", "blurb": "A detective investigates a legendary demon dog said to haunt a family on the lonely Devon moors."}
```

Both are set on the moors and both turn on a family. The model compared what the blurbs
describe and found them close; it knows nothing of shelves.

The second list looks better: four of the five books under **The Time Machine** are science
fiction. The first is not. **Around the World in Eighty Days** is an adventure, and it leads at
0.395, presumably because both blurbs follow a Victorian Englishman on an extraordinary journey.
The model does not say why, and a guess like that is all a reader of the scores can make.

**Neither list is wrong in the way a search is wrong.** A customer who liked the Hound for its
atmosphere may well enjoy Wuthering Heights. But it is a different idea of *like* from the one a
bookseller has, and you choose between them, mostly through what you embed.

## What you embed decides what *similar* means

One way to see what the model is matching on is to count how often a book's five nearest
neighbours share its genre, across the whole catalogue:

```schooling-example
{
  "language": "python",
  "file": "genres.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom minilm import embed\nfrom books import B, books\n\ngenre = np.array([b[\"genre\"] for b in books])",
      "note": "The genre of every book, as an array in the same order as the vectors."
    },
    {
      "code": "def agreement(V):\n    S = V @ V.T\n    np.fill_diagonal(S, -np.inf)\n    top = np.argsort(-S, axis=1)[:, :5]\n    return int((genre[top] == genre[:, None]).sum())",
      "note": "For every book, its five nearest other books; the diagonal is set to minus infinity so that a book is never its own neighbour. Count how many of the 300 share the book's genre."
    },
    {
      "code": "same = [(genre == g).sum() - 1 for g in genre]\nchance = sum(5 * s / (len(books) - 1) for s in same)\nprint(f\"chance:              {chance:.1f} of 300\")\nprint(f\"title. blurb:        {agreement(B)} of 300\")",
      "note": "What chance would give: for each book, five picks from the 59 others, of which `same` share its genre."
    },
    {
      "code": "G = embed([b[\"genre\"] + \". \" + b[\"title\"] + \". \" + b[\"blurb\"] for b in books])\nprint(f\"genre. title. blurb: {agreement(G)} of 300\")",
      "note": "The same count for vectors of the genre, title and blurb together."
    }
  ]
}
```

```
ana@lab:~/emb$ python genres.py
chance:              34.2 of 300
title. blurb:        94 of 300
genre. title. blurb: 235 of 300
```

Sixty books with five neighbours each is 300 neighbours. If neighbours were picked at random, about
34.2 of them would share the book's genre, the `chance` line. Title and blurb give **94 of 300**:
well above chance, and still fewer than a third. The blurbs describe plots, and plots cross genres.

Putting the genre into the embedded text, as its first words, raises the count to **235**. That is
not the model getting better. It is you telling it what to care about, and the choice has a cost. A
genre written into every vector pulls each book towards its shelf and away from the
mystery-on-the-moors kind of match, which some readers want.

So the text that goes into the embedding is a design decision, like the columns of a table. Title
and blurb make a row that recommends by story; genre in front makes a row that recommends by shelf.
A shop can keep both and show both rows, since a vector for sixty books costs nothing.

This lesson keeps title and blurb, because the surprises are what it is about. Every number from
here on comes from those vectors.
