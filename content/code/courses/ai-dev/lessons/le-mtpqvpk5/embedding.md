---
title: An index of vectors
version: 1
---

To search by meaning, every passage is turned into an embedding once, ahead of time, and kept. A
question is embedded when it arrives, and compared with all of them. Lesson 1 section 09 showed what
an embedding is and what it cannot see; this section stores them.

## Building the index

```python
def build():
    cs = chunks()
    vectors = WordLlama.load().embed([c["text"] for c in cs], norm=True)
    INDEX.mkdir(exist_ok=True)
    np.save(INDEX / "vectors.npy", vectors)
    (INDEX / "chunks.json").write_text(json.dumps(cs, indent=1))
    return cs, vectors
```

```
ana@dev:~/shop$ time PYTHONPATH=scratch python -c 'import rag; cs, v = rag.build(); print(len(cs), "chunks,", v.shape, v.dtype)'
26 chunks, (26, 256) float32

real	0m1.016s
user	0m1.020s
sys	0m0.250s
ana@dev:~/shop$ ls -la .rag
total 44
drwxr-xr-x 2 ana ana  4096 Oct  7 15:07 .
drwxr-xr-x 8 ana ana  4096 Oct  7 15:07 ..
-rw-r--r-- 1 ana ana  5881 Oct  7 15:07 chunks.json
-rw-r--r-- 1 ana ana 26752 Oct  7 15:07 vectors.npy
```

Twenty-six vectors of 256 numbers, in under two seconds on a laptop processor, most of it loading
the model. The index is two files: the vectors, 26,752 bytes as a numpy array, and the passages with
their ids. **That is a vector database at its smallest**: a matrix, and a list that says which row is
which passage.

## When to reach for a real one

A matrix in memory and one multiplication per question is the right tool up to tens of thousands of
passages; the comparison takes milliseconds. Past that, or when the index has to be shared, updated
while it is being searched or filtered by fields (only this customer's tickets, only documents from
this year), a vector database or a vector extension to the database you already run takes over. They
store the same vectors and answer the same question, faster, with an approximate search that trades
a little recall for a lot of speed.

Three rules hold at any size:

- **Embed the question and the passages with the same model.** Vectors from two models are not on
  the same axes, and comparing them gives numbers that look like scores and mean nothing.
- **Rebuild when the model changes.** A new embedding model means a new index, every passage again.
- **Rebuild when the documents change**, at least the passages that changed. An index older than the
  handbook answers from rules the shop no longer has, with a citation that looks perfectly good.
