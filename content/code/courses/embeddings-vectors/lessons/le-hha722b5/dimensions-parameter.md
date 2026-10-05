---
title: The dimensions parameter
version: 1
---

text-embedding-3-small returns 1,536 numbers and text-embedding-3-large 3,072. That is a lot to
store for every chunk of every document, and lesson 18 adds up the bill. OpenAI's answer, for the
text-embedding-3 models, is a request parameter: **`dimensions`** asks for a shorter vector, and
OpenAI describes the shorter vector as trading some accuracy for size.

It can work because, by OpenAI's account, those models were trained so that the **first**
coordinates carry the most information, and a prefix of the vector is a usable vector on its own.
Not every model is built like that. An ordinary model spreads what it learned over all its coordinates, and
cutting its vector loses part of that with no promise about which part.

The lab has one model trained that way. WordLlama's 256 numbers were trained so that the first 64
or 128 still work alone, and labembed serves it as `lab-wordllama` with `dimensions` from 1 to 256.
So the trade can be measured, with lesson 3's 24 questions and their answers:

```schooling-example
{
  "language": "python",
  "file": "dims.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nimport openai\nfrom openai import OpenAI\n\nclient = OpenAI()\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\nqueries = [json.loads(l) for l in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]\ndocs = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nasks = [q[\"text\"] for q in queries]\n\n\ndef embed(texts, **kw):\n    r = client.embeddings.create(model=\"lab-wordllama\", input=texts, **kw)\n    return np.array([d.embedding for d in r.data], dtype=np.float32)\n\n\ndef recall(D, Q):\n    top = np.argsort(-(Q @ D.T), axis=1)[:, :3]\n    at1 = sum(ids[t[0]] in q[\"relevant\"] for t, q in zip(top, queries))\n    at3 = sum(any(ids[i] in q[\"relevant\"] for i in t) for t, q in zip(top, queries))\n    return f\"recall@1 {at1}/{len(queries)}  recall@3 {at3}/{len(queries)}\"",
      "note": "`embed` asks `lab-wordllama` for vectors, passing `dimensions` through when given. `recall` is lesson 3's measurement: how many of the 24 questions find a right article first, and in the top three."
    },
    {
      "code": "for dims in (256, 128, 64):\n    D, Q = embed(docs, dimensions=dims), embed(asks, dimensions=dims)\n    print(f\"dimensions={dims:<3}  {D[0].nbytes:4} bytes a vector  {recall(D, Q)}\")",
      "note": "Ask the API for 256, 128 and 64 numbers, and measure each size on the same questions."
    },
    {
      "code": "D, Q = embed(docs)[:, :64], embed(asks)[:, :64]\nlengths = np.linalg.norm(D, axis=1)\nprint(f\"cut to 64 by hand: lengths {lengths.min():.2f} to {lengths.max():.2f}  {recall(D, Q)}\")\nD /= np.linalg.norm(D, axis=1, keepdims=True)\nQ /= np.linalg.norm(Q, axis=1, keepdims=True)\nprint(f\"cut, then renormalised:           {recall(D, Q)}\")",
      "note": "Now take the full 256 and keep the first 64 yourself. The cut vectors are no longer of length 1; measure them as they are, then divide each by its length and measure again."
    },
    {
      "code": "try:\n    client.embeddings.create(model=\"lab-minilm\", input=\"Tracking a parcel\", dimensions=128)\nexcept openai.BadRequestError as e:\n    print(\"lab-minilm, dimensions=128:\", e.status_code, e.body[\"message\"])",
      "note": "`lab-minilm` is a model with one fixed size, like text-embedding-ada-002."
    }
  ]
}
```

```
ana@lab:~/emb$ python dims.py
dimensions=256  1024 bytes a vector  recall@1 20/24  recall@3 24/24
dimensions=128   512 bytes a vector  recall@1 17/24  recall@3 23/24
dimensions=64    256 bytes a vector  recall@1 20/24  recall@3 21/24
cut to 64 by hand: lengths 0.56 to 0.70  recall@1 19/24  recall@3 20/24
cut, then renormalised:           recall@1 20/24  recall@3 21/24
lab-minilm, dimensions=128: 400 This model does not support specifying dimensions.
```

## What the numbers say

**Halving the vector cost less than halving it suggests.** At 128 numbers each vector takes half
the bytes and finds a right article in the top three for 23 of 24 questions, against 24 at full
size. At 64 it finds 21. The first-place count moves around more, and 24 questions are few enough
that one question is four points; read the column as a trend, not a ranking of the sizes.

What the measurement does not tell you is how text-embedding-3 behaves. It is a different model on
different text, and OpenAI's own figures are about benchmarks, not your help centre. The method
carries over: run your own questions at each size before choosing one.

## Cutting it yourself

`dimensions` is a convenience. You could ask for the full vector and keep the first 64 numbers
yourself, and the third part of the program does. The cut vectors are no longer of length 1: their
lengths spread out, as the output shows, because each text kept a different share of its length
in its first 64 numbers. Ranked by dot product as they are, longer vectors win for being long,
which lesson 2 warned about, and the result is a question worse than the API's.

**Divide each cut vector by its length** and the numbers match the API's exactly, because that is
what the server did. If you shorten stored vectors yourself, renormalise them in the same step,
and do the same to every query.

## A model with one size

The last line is `lab-minilm` refusing `dimensions`. all-MiniLM-L6-v2 was not trained to be cut,
so the lab answers the way OpenAI documents for text-embedding-ada-002, its older model: the
parameter is not supported. Check that a model accepts `dimensions` before building on it; a model
that silently ignored it would hand you 1,536 numbers where your table expects 256.
