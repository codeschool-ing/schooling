---
title: Cold start
version: 1
---

A recommender is easy to judge on readers with a long history. The hard cases are at the edges: a
book nobody has read yet, and a reader who has read nothing. Both are called the **cold start**,
and the method in this lesson handles them very differently, one well and one not at all.

```schooling-example
{
  "language": "python",
  "file": "coldstart.py",
  "parts": [
    {
      "code": "from collections import Counter\nimport numpy as np\nfrom minilm import embed\nfrom books import B, books, readers, row, show",
      "note": "The same helpers, and `Counter` for the popularity list."
    },
    {
      "code": "new = embed(\"The Lost World. A professor leads an expedition to a remote plateau \"\n            \"in South America where dinosaurs still roam.\")[0]\nprint(\"The Lost World, nearest in the catalogue:\")\nshow(B @ new)",
      "note": "A book that is not in the catalogue: embed its title and blurb, and show its nearest books."
    },
    {
      "code": "print(\"readers who would see it in their top 5:\")\nfor r in readers.values():\n    if not r[\"finished\"]:\n        continue\n    v = B[[row[i] for i in r[\"finished\"]]].mean(axis=0)\n    v /= np.linalg.norm(v)\n    unread = [B[i] @ v for i in range(len(books)) if books[i][\"id\"] not in r[\"finished\"]]\n    rank = 1 + sum(s > new @ v for s in unread)\n    if rank <= 5:\n        print(f\"  {r['name']:6} rank {rank}  ({new @ v:.3f})\")",
      "note": "For every reader who has finished something, count how many of their unread books score higher than the new one. Print the readers for whom it would make the top five."
    },
    {
      "code": "print(\"Marcos has finished:\", readers[\"r11\"][\"finished\"])\ncounts = Counter(i for r in readers.values() for i in r[\"finished\"])\nfor book_id, n in counts.most_common(3):\n    print(f\"  {n} readers  {books[row[book_id]]['title']}\")",
      "note": "Marcos has finished nothing. Count how many readers finished each book, and show the three most finished."
    },
    {
      "code": "q = embed(\"ghost stories and haunted houses\")[0]\nprint(\"Marcos asked for ghost stories:\")\nshow(B @ q, n=3)",
      "note": "Or ask him, and embed his answer as if it were a book."
    }
  ]
}
```

```
ana@lab:~/emb$ python coldstart.py
The Lost World, nearest in the catalogue:
  0.643  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.467  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.439  b15  science fiction Frankenstein  (Mary Shelley)
  0.397  b16  science fiction Twenty Thousand Leagues Under the Sea  (Jules Verne)
  0.392  b47  non-fiction     Walden  (Henry David Thoreau)
readers who would see it in their top 5:
  Caio   rank 1  (0.540)
  Íris   rank 3  (0.374)
Marcos has finished: []
  3 readers  The Hound of the Baskervilles
  2 readers  Pride and Prejudice
  2 readers  Dracula
Marcos asked for ghost stories:
  0.572  b21  horror          The Turn of the Screw  (Henry James)
  0.470  b38  literary        Bleak House  (Charles Dickens)
  0.392  b07  mystery         The Hound of the Baskervilles  (Arthur Conan Doyle)
```

## A new book has a vector at once

*The Lost World* is not in the catalogue. Its blurb, written into the program, is embedded the same
way as the other sixty, and the book is ready to recommend before a single copy is sold: its nearest
neighbour is *Journey to the Centre of the Earth*, at 0.643, another professor on an expedition to a
lost prehistoric world. The second half of the program asks every reader's vector where the new
book would rank among the books they have not read. **Caio would see it first.**

Íris would see it third, at 0.374, and she has finished *Walden*, *Meditations* and *On the Origin
of Species*. A professor who finds dinosaurs still alive is probably close to a book about
species changing over generations in the model's eyes, and whether a reader of philosophy wants an
adventure is something only she can say. It is a reasonable guess, made on the first day, from text
alone.

That is the strength of **content-based** recommendation, which is everything this lesson has
built: the recommendation comes from what the book is, so it needs nothing from other readers.

## A new reader has no vector at all

Marcos has an account and has finished nothing. The average of no vectors is not a vector, and no
amount of similarity search fixes that. Two fallbacks are common, and the program shows both.

**Show what is popular.** The books finished by the most readers: *The Hound of the Baskervilles*,
finished by 3, then *Pride and Prejudice* and *Dracula* with 2 each. It is a list that is right for
the average customer and for nobody in particular, and with twelve readers it rests on a handful of
counts. In a real shop the counts come from thousands of readers and the list is a sensible
default.

**Ask.** A sign-up question, *what do you like to read?*, gives a sentence, and a sentence can be
embedded like anything else. *Ghost stories and haunted houses* finds **The Turn of the Screw** at
0.572, a ghost story in a remote country house, which is exactly right. It also finds **Bleak
House** at 0.470, which is about a lawsuit, because its title contains the word *house*. The model
compares everything it is given, title words included, and a short query puts a lot of weight on
each word.

## A reader with one book

Nina has finished one book, *Around the World in Eighty Days*. Her vector is that book's vector,
and her recommendations are the row under that book:

```
ana@lab:~/emb$ python reader.py r12
Nina finished: Around the World in Eighty Days
length of the average: 1.000
  0.395  b13  science fiction The Time Machine  (H. G. Wells)
  0.376  b16  science fiction Twenty Thousand Leagues Under the Sea  (Jules Verne)
  0.369  b56  mystery         The Thirty-Nine Steps  (John Buchan)
  0.344  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.312  b25  adventure       Treasure Island  (Robert Louis Stevenson)
ana@lab:~/emb$ python like.py b28
b28 Around the World in Eighty Days - adventure
  0.395  b13  science fiction The Time Machine  (H. G. Wells)
  0.376  b16  science fiction Twenty Thousand Leagues Under the Sea  (Jules Verne)
  0.369  b56  mystery         The Thirty-Nine Steps  (John Buchan)
  0.344  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.312  b25  adventure       Treasure Island  (Robert Louis Stevenson)
```

The two lists are identical, and the length of the average, 1.000, says why: an average of one unit
vector is that vector. With one book there is no taste to average yet, only a single example, and
the list will change a great deal with her second and third.

## The other way to build a reader

Everything here is content-based. The other family of recommenders, **collaborative filtering**,
never reads a blurb. It learns a vector for every reader and every book from who finished what
alone, so that books finished by the same people end up close together; *readers like you also
read* is its signature. It finds connections no blurb contains, and it fails exactly where this
lesson succeeds: a new book that nobody has read has no vector in it at all.

With twelve readers it would have nothing to learn from, which is why this lesson does not build
it. Learning those vectors is matrix factorisation, which `machine-learning` teaches. Real shops
tend to combine the two, content to place a new book on its first day and the record of who read
what once there is one.
