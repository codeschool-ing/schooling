---
title: The data model
version: 1
---

Every vector database organises its data the same way, under different names. **A collection holds
records, and a record is an id, a vector, metadata and, usually, the text.** Chroma and Qdrant call
the container a collection, Pinecone an index, pgvector a table, LanceDB a table too; lessons 12 to
14 meet each one. The four parts of a record are the same in all of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A nested diagram of a collection. The outer box is the collection, with the facts fixed when it was created: the model all-MiniLM-L6-v2, the dimension 384, and the comparison, a dot product of unit vectors. Inside it, records in rows, each with four parts: an id, a vector of 384 numbers, metadata with category, language and date, and the text. Three example rows are h14, h15 and h18; h18 is crossed out as a tombstone, still in the array until the next save.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">a collection</text><text x=\"26\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fixed at creation:</text><text x=\"170\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">all-MiniLM-L6-v2</text><text x=\"320\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">384</text><text x=\"360\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dot product of unit vectors</text><text x=\"65\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">id</text><text x=\"195\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vector</text><text x=\"395\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">metadata</text><text x=\"595\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">text</text><text x=\"26\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a record</text><rect x=\"30\" y=\"116\" width=\"64\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"116\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"290\" y=\"116\" width=\"204\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"500\" y=\"116\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h14</text><text x=\"192\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">[ … ]</text><text x=\"392\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">returns  en  2026-02-02</text><text x=\"592\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">How to return a book. You have…</text><rect x=\"30\" y=\"168\" width=\"64\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"168\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"290\" y=\"168\" width=\"204\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"500\" y=\"168\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h15</text><text x=\"192\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">[ … ]</text><text x=\"392\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">returns  en  2026-10-05</text><text x=\"592\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">When your refund arrives. We…</text><rect x=\"30\" y=\"220\" width=\"64\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"100\" y=\"220\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"290\" y=\"220\" width=\"204\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"500\" y=\"220\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"62\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">h18</text><text x=\"192\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">[ … ]</text><text x=\"392\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">returns  en  2026-01-08</text><text x=\"592\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Returning a gift. The person…</text><path d=\"M30 239 L684 239\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"30\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">deleted: a tombstone until the next save</text><text x=\"192\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">384 numbers</text></svg>", "caption": "A collection fixes its model, its dimension and its comparison once. Every record inside has the same four parts, and a deleted record stays as a tombstone until the store is compacted."}
```

## The record

**The id is yours, and it is the join.** A search returns ids and scores; everything a person reads
comes from following the id back to the source. In `tinystore.py` the id is the article's own id,
`h15`, which is what makes an update possible: writing `h15` again means *this article changed*,
not *here is another one*. A store that invents its own ids for you leaves you a second lookup to
keep in step, the same problem as the separate list beside a NumPy matrix.

**The vector is the only part the search compares.** It is what the model produced from the text,
and it is meaningless without knowing which model that was.

**The metadata is what you filter and sort by**: the category, the language and the date here,
and in a real shop the stock, the price, the customer an item belongs to. It is stored beside the
vector so that "only English articles" is part of the same query, as `path.py` does in the last
section of this lesson. Lesson 17 is about how a database combines that filter with the search, and
why the order of the two matters.

**The text is optional, and storing it is a choice.** Keeping it in the record saves a second
lookup to fetch what the search found. Keeping it only in the shop's own database avoids two copies
that can drift apart. Chroma stores it as a `document`; with others you put it in the metadata
yourself or keep it elsewhere.

## The collection fixes three things once

**A collection holds the vectors of one model, so its model and its dimension are fixed when it is
created**, and so is the comparison it uses. `tinystore.py` normalises every vector and compares by
dot product, which for unit vectors is cosine similarity, as lesson 2 showed. Chroma asks for the
comparison as a `space` when the collection is created, and pgvector bakes it into the operator and
the index. Changing any of the three means a new collection, which is lesson 10's migration.

The small store enforces the first two, and its refusals are the point:

```schooling-example
{
  "language": "python",
  "file": "refuse.py",
  "parts": [
    {
      "code": "from minilm import embed\nfrom wordllama import WordLlama\nfrom tinystore import Store\n\nstore = Store.load(\"store\")\nprint(store.model, store.dim, len(store.ids), \"records\")",
      "note": "Load the store and print what the collection says about itself."
    },
    {
      "code": "other = WordLlama.load().embed([\"how do I get my money back\"], norm=True)[0]\ntry:\n    store.upsert(\"h99\", other, {}, \"how do I get my money back\")\nexcept ValueError as e:\n    print(\"ValueError:\", e)",
      "note": "Try to store a WordLlama vector in a MiniLM collection."
    },
    {
      "code": "q = embed(\"how do I get my money back\")[0]\ntry:\n    store.search(q, model=\"lab-minilm\")\nexcept ValueError as e:\n    print(\"ValueError:\", e)",
      "note": "Search with a MiniLM vector but name another model, as code that forgot which model a collection holds would."
    }
  ]
}
```

```
ana@lab:~/emb$ python refuse.py
all-MiniLM-L6-v2 384 40 records
ValueError: all-MiniLM-L6-v2 vectors have 384 numbers, got (256,)
ValueError: this collection holds all-MiniLM-L6-v2 vectors, not lab-minilm
```

**The first refusal is the easy one.** A WordLlama vector has 256 numbers, the collection expects
384, and no arithmetic can join them. Every real database refuses this too, with its own message.

**The second refusal is the one that saves you.** The question's vector came from all-MiniLM-L6-v2,
and `lab-minilm` is labembed's name for that very same model. The store cannot know that: it compares
names, not weights, and it refuses. That is the right side to fail on: a search that trusted
whatever vector it was handed would also take one from a different model with the same dimension,
the silent failure lesson 10 measured. So the name has to be one string, written the same way
everywhere. The store checks it only on the way out. `upsert` checks the dimension and trusts its
caller about the model, a gap a real system closes by embedding in one place only.

Most real databases never ask for the model's name. Chroma comes closest: it can embed the text for
you with an embedding function tied to the collection, which lesson 12 shows. pgvector and Qdrant
know only the dimension. Where the database does not keep the model's name, you keep it: in the
collection's name, in its metadata, or in a table beside it.
