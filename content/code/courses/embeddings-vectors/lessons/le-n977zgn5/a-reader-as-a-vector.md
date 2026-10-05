---
title: A reader as a vector
version: 1
---

A row under a book answers *what is like this one*. A page for a signed-in reader has to answer
*what would she like*, and that needs a vector for the reader. The simplest one is built from what
she has already finished: **average the vectors of her books, and renormalise**. Her
recommendations are then the unread books nearest that average, the same search again.

```schooling-example
{
  "language": "python",
  "file": "reader.py",
  "parts": [
    {
      "code": "import sys\nimport numpy as np\nfrom books import B, books, readers, row, show\n\nr = readers[sys.argv[1]]\nmine = [row[i] for i in r[\"finished\"]]\nprint(r[\"name\"], \"finished:\", \", \".join(books[i][\"title\"] for i in mine))",
      "note": "Find the reader named on the command line and the rows of the books she finished."
    },
    {
      "code": "v = B[mine].mean(axis=0)\nprint(f\"length of the average: {np.linalg.norm(v):.3f}\")\nv /= np.linalg.norm(v)",
      "note": "Her vector is the average of theirs. Print its length, then divide by it."
    },
    {
      "code": "show(B @ v, skip=set(r[\"finished\"]))",
      "note": "Her recommendations are the books nearest her vector, minus the ones she has finished."
    }
  ]
}
```

```
ana@lab:~/emb$ python reader.py r02
Caio finished: The Time Machine, The War of the Worlds, Twenty Thousand Leagues Under the Sea
length of the average: 0.669
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
  0.400  b18  science fiction The Invisible Man  (H. G. Wells)
ana@lab:~/emb$ python reader.py r10
Lia finished: Pride and Prejudice, The Hound of the Baskervilles
length of the average: 0.777
  0.535  b04  romance         Wuthering Heights  (Emily Brontë)
  0.467  b11  mystery         The Mysterious Affair at Styles  (Agatha Christie)
  0.440  b32  literary        Great Expectations  (Charles Dickens)
  0.405  b60  adventure       The Scarlet Pimpernel  (Baroness Orczy)
  0.404  b03  romance         Jane Eyre  (Charlotte Brontë)
```

**Caio** has finished three science-fiction books, and his list is what you would hope: two by
Verne, two by Wells and *Moby-Dick*, science fiction and sea and travel adventures. His average
had length 0.669 before it was renormalised, which says, as in lesson 4, that his three books point
in fairly different directions; the renormalised average is the direction they share.

## A reader with two tastes

**Lia** has finished two books: *Pride and Prejudice*, a romance, and *The Hound of the
Baskervilles*, a mystery. Her list is led by **Wuthering Heights** at 0.535, and the reason shows
when each candidate is scored against her two books separately:

```schooling-example
{
  "language": "python",
  "file": "between.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom books import B, books, readers, row\n\nmine = [row[i] for i in readers[\"r10\"][\"finished\"]]\nv = B[mine].mean(axis=0)\nv /= np.linalg.norm(v)\nprint(\"        lia   \" + \"  \".join(books[i][\"id\"] for i in mine))\nfor i in [i for i in np.argsort(-(B @ v)) if i not in mine][:5]:\n    cols = \"  \".join(f\"{B[i] @ B[j]:.3f}\" for j in mine)\n    print(f\"{books[i]['id']}  {B[i] @ v:.3f}  {cols}  {books[i]['title']}\")",
      "note": "Lia's vector, built as in `reader.py`. For her top five unread books, print the score against her vector and then against each of her two books, one column per book."
    }
  ]
}
```

```
ana@lab:~/emb$ python between.py
        lia   b01  b07
b04  0.535  0.388  0.444  Wuthering Heights
b11  0.467  0.328  0.397  The Mysterious Affair at Styles
b32  0.440  0.424  0.260  Great Expectations
b60  0.405  0.285  0.344  The Scarlet Pimpernel
b03  0.404  0.265  0.363  Jane Eyre
```

**Wuthering Heights scores 0.388 against one of her books and 0.444 against the other.** It is
fairly close to both, and that is what puts it first. *The Adventures of Sherlock Holmes* is nearly
as close to the Hound, 0.411, and only 0.200 to *Pride and Prejudice*, so it is not on the list at
all. The score against the renormalised average is the sum of the scores against each book,
divided by one constant, the length of their sum. A book fairly close to both beats a book right
beside one of them and far from the other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 470\" role=\"img\" aria-label=\"A scatter plot of the 58 books Lia has not read. The horizontal axis is each book's similarity to Pride and Prejudice, the vertical axis its similarity to The Hound of the Baskervilles. The five books recommended from the average of her two, marked as hollow circles, sit furthest towards the top right along a diagonal: Wuthering Heights, The Mysterious Affair at Styles, Great Expectations, The Scarlet Pimpernel and Jane Eyre. Sense and Sensibility, close to Pride and Prejudice only, and The Adventures of Sherlock Holmes, close to the Hound only, fall below the dashed diagonal that the fifth recommendation sits on.\"><path d=\"M80 390 L80 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 390 L680 390\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><text x=\"72\" y=\"390\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M200 390 L200 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 322 L680 322\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"200\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><text x=\"72\" y=\"322\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M320 390 L320 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 254 L680 254\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"320\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.2</text><text x=\"72\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M440 390 L440 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 186 L680 186\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.3</text><text x=\"72\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.3</text><path d=\"M560 390 L560 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 118 L680 118\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"560\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><text x=\"72\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M680 390 L680 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 50 L680 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><text x=\"72\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M80 390 L680 390\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 390 L80 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M233.6 50 L680 303\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"526.4\" cy=\"239\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"398\" cy=\"143.2\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"390\" y=\"157.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Jane Eyre</text><circle cx=\"545.6\" cy=\"88.1\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"535.6\" y=\"88.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Wuthering Heights</text><circle cx=\"387.2\" cy=\"321.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"478.4\" cy=\"332.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"304.4\" cy=\"147.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"309.2\" cy=\"211.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"374\" cy=\"212.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"473.6\" cy=\"120\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"483.6\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">The Mysterious Affair at Styles</text><circle cx=\"359.6\" cy=\"184.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"260\" cy=\"230.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"242\" cy=\"310.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"314\" cy=\"205.7\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"185.6\" cy=\"308.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"282.8\" cy=\"246.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"237.2\" cy=\"229.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"269.6\" cy=\"137.7\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"394.4\" cy=\"192.1\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"300.8\" cy=\"183.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"257.6\" cy=\"269.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"340.4\" cy=\"213.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"338\" cy=\"176.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"330.8\" cy=\"207.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"309.2\" cy=\"202.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"275.6\" cy=\"222.7\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"270.8\" cy=\"281.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"250.4\" cy=\"210.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"155.6\" cy=\"129.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"306.8\" cy=\"231.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"588.8\" cy=\"213.2\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"598.8\" y=\"213.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Great Expectations</text><circle cx=\"497.6\" cy=\"222\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"478.4\" cy=\"330.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"490.4\" cy=\"202.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"424.4\" cy=\"193.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"358.4\" cy=\"221.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"306.8\" cy=\"150.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"334.4\" cy=\"239\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"345.2\" cy=\"296.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"407.6\" cy=\"245.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"455.6\" cy=\"253.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"358.4\" cy=\"216.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"340.4\" cy=\"186\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"428\" cy=\"189.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"478.4\" cy=\"189.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"413.6\" cy=\"257.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"168.8\" cy=\"261.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"520.4\" cy=\"238.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"519.2\" cy=\"349.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"333.2\" cy=\"313.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"262.4\" cy=\"325.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"354.8\" cy=\"136.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"480.8\" cy=\"280.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"320\" cy=\"110.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"310\" y=\"110.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">The Adventures of Sherlock Holmes</text><circle cx=\"278\" cy=\"224.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"360.8\" cy=\"134.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"258.8\" cy=\"179.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"580.4\" cy=\"264.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"570.4\" y=\"264.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Sense and Sensibility</text><circle cx=\"422\" cy=\"156.1\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"432\" y=\"156.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">The Scarlet Pimpernel</text><text x=\"380\" y=\"424\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">similarity to Pride and Prejudice</text><text x=\"80\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">similarity to The Hound of the Baskervilles</text><circle cx=\"96\" cy=\"452\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"110\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">recommended from the average</text><circle cx=\"310\" cy=\"452\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"322\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">other unread books</text><path d=\"M500 452 L528 452\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"536\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the fifth one's diagonal</text></svg>", "caption": "Every book Lia has not read, placed by its similarity to each of her two. Ranking by the average is ranking by distance along the diagonal: the five recommended books are the ones furthest towards the top right, and a book close to only one of hers falls short of the dashed line."}
```

The figure plots every book Lia has not read by its similarity to each of her two. The average's
ranking runs diagonally across it: a book's place depends on how far up and to the right it sits,
and the five recommended ones are the furthest along that diagonal. A book in the top-left or
bottom-right corner, very close to one of her books and far from the other, loses to the middle.

**Sometimes the middle is what the reader wants**, a gothic romance for somebody who read a romance
and a gothic mystery. Sometimes it is a book that suits neither of her moods. The average cannot
tell which, because it has thrown away the fact that there were two books. A system that wants to
keep both tastes keeps them apart: one vector per cluster of what the reader finished, each
searched on its own, and the results merged. That is more machinery, and with two finished books
there is no cluster to find; the average is where every recommender starts.

## Everything she read counts the same

The average treats a book Lia finished last week and one she finished three years ago as equal,
and a book she loved like one she abandoned at the last page. Real systems weight the average:
recent books more, rated books by their rating, books returned for a refund negatively. Each weight
is a guess about what the reader meant, and the way to choose between guesses is the one lesson 4
used for classifiers: hold some of each reader's history back and check whether the recommendations
would have found it.
