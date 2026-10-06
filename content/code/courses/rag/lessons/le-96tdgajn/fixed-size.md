---
title: Fixed-size chunks
version: 1
---

The simplest way to cut is by count: every so many words, or characters, or tokens, start a new
chunk. It needs no knowledge of the document at all, which is both why it is the default in most
libraries and why it does damage.

```python
def fixed(text, size, overlap=0):
    """Every SIZE words, starting again OVERLAP words before the last cut."""
    words = text.split()
    step = size - overlap
    return [" ".join(words[i:i + size]) for i in range(0, max(len(words) - overlap, 1), step)]
```

`fixed` counts words, which is easy to read and close enough for English prose. Libraries usually
count characters, and the careful ones count the embedding model's own tokens, which is what the
limit in the last section is measured in. The behaviour is the same whatever the unit: a cut lands
wherever the count says, regardless of what is there.

## Where the cuts land

`boundaries.py` cuts the returns policy into 60-word chunks and prints the edges of three of them,
counting from 0:

```
ana@lab:~/rag$ python boundaries.py 60 0
15 chunks of 60 words, 0 overlapping
chunk 3 starts: to you at our cost with an email explaining ...
chunk 3 ends:   ... choose Return items. 2. Select the books you are
chunk 4 starts: sending back and a reason. The reason helps us; ...
chunk 4 ends:   ... in the box, and drop the parcel at any
chunk 5 starts: post office. Returns are free. You do not pay ...
chunk 5 ends:   ... reaching our warehouse. The money goes back to the
```

**Every boundary is mid-sentence.** Chunk 3 begins with *to you at our cost*, the end of a sentence
whose subject is in chunk 2. Chunk 3 ends with *Select the books you are*, and the rest of that
instruction is in chunk 4. Chunk 4 ends *drop the parcel at any* and chunk 5 begins *post office*.
Each chunk is a window of text with ragged ends, and the ends are where the meaning leaks out.

The damage is easiest to see in the sentence the customer most needs. *Returns are free* sits at the
start of chunk 5, in a chunk that otherwise talks about refunds and banks. A question about postage
is now compared with a vector that is mostly about refunds.

## What it gets right

Fixed-size chunking has real virtues, and they are why it survives:

- **Every chunk is under the limit**, by construction. Set the size below the embedding model's
  limit, in the model's own units, and nothing is ever truncated.
- **It works on any text**: a transcript with no paragraphs, a PDF whose structure was lost in
  extraction, a log file.
- **Chunks are of even size**, so each retrieved chunk costs about the same in the prompt.

Those virtues matter when the text has no structure to follow. When it has some, as almost every
document a company writes does, ignoring it is a choice to cut sentences in half. The next section
softens the damage without looking at the structure; the one after it uses the structure.
