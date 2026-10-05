---
title: Running a model on your own machine
version: 1
---

Lessons 7 and 8 sent every text to a provider and paid per token. An **open model** turns that
around: its weights are a file anybody may download, and once the file is on your disk the model
runs on your processor, as often as you like, with nobody else involved.

Four things follow from that, and they are the usual reasons to choose one.

- No bill per text. Embedding the help centre a hundred times costs electricity. The cost moves
  to the machine that runs it, which this lesson's last section measures.
- Nothing leaves. A customer's message is embedded where it is stored. Lesson 1 argued that a
  vector is personal data too; with an open model neither the text nor the vector crosses to a
  third party.
- It works offline, and the latency is your own machine's rather than a round trip.
- It never changes under you. A file with a checksum is the same model next year. A hosted
  model can be updated or retired by its provider, and every stored vector then has to be made
  again, which lesson 18 prices.

What you take on in exchange is the running: the memory, the processor time, and the upgrades
nobody will do for you.

## The usual way, which did not run here

Most open embedding models are published on **Hugging Face**, a site that hosts model files the way
a package index hosts libraries. Most people run them with **sentence-transformers**, the library
from the project that published all-MiniLM-L6-v2. This is the whole program:

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
print(model.max_seq_length, model.get_sentence_embedding_dimension())

vectors = model.encode(
    ["When your refund arrives", "Tracking a parcel"],
    normalize_embeddings=True,
)
print(vectors.shape)
```

**This program was not run for this course.** The first call to `SentenceTransformer` downloads the
model from huggingface.co into a local cache, and the library itself installs PyTorch, whose
package index was also out of reach. Asking huggingface.co for the model's page shows why:

```
ana@lab:~/emb$ curl -sS -D - -o /dev/null https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2 | head -n 2
HTTP/2 403 
x-deny-reason: host_not_allowed
```

The network this machine sits on refuses the host. So nothing below claims what `st.py` would
print. Its first line asks the model for its maximum input and its dimension, which the model card
gives as 256 and 384, and the next section opens up what `encode` does with them.

## The same weights, another way

The model itself is not tied to the library. Chroma, the vector database lesson 12 runs, ships
all-MiniLM-L6-v2 exported to **ONNX**, a format that a small runtime called onnxruntime can execute
without PyTorch. `lab.sh` downloaded that export from Chroma's own storage and checked it against
the SHA-256 that Chroma's code carries, so these are the published weights and not a copy of
unknown origin:

```
ana@lab:~/emb$ ls -l $MINILM_DIR
total 89208
-rw-r--r-- 1 root root      650 Oct  5 13:23 config.json
-rw-r--r-- 1 root root 90387606 Oct  5 13:23 model.onnx
-rw-r--r-- 1 root root      125 Oct  5 13:23 special_tokens_map.json
-rw-r--r-- 1 root root   711661 Oct  5 13:23 tokenizer.json
-rw-r--r-- 1 root root      518 Oct  5 13:23 tokenizer_config.json
-rw-r--r-- 1 root root   231508 Oct  5 13:23 vocab.txt
```

`model.onnx` is the transformer, 90,387,606 bytes. The rest is the tokenizer and its settings.
`minilm.py`, which every lesson so far has imported, wraps them in fifty lines:

```schooling-example
{
  "language": "python",
  "file": "local.py",
  "parts": [
    {
      "code": "from minilm import embed\n\nvectors = embed([\"When your refund arrives\", \"Tracking a parcel\"])\nprint(vectors.shape)\nprint(round(float(vectors[0] @ vectors[1]), 4))",
      "note": "Two titles through `minilm.py`: two vectors of 384 numbers, and their dot product."
    }
  ],
  "output": "ana@lab:~/emb$ python local.py\n(2, 384)\n0.1653"
}
```

Two texts in, two vectors of 384 numbers out, and a dot product of 0.1653 between a refund title
and a tracking title, which have little to do with each other. That is the same computation
`model.encode(..., normalize_embeddings=True)` performs; the next section takes it apart and checks
the result against Chroma's own code to eight decimal places.
