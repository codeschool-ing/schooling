---
title: Distances, not scores
version: 1
---

Lesson 1 scored *Returning a gift* at 0.446 against the customer's question, and Chroma gave the
same article 0.5544. Both are right. **A score grows as two vectors get closer; a distance shrinks.**
Every vector database picks one convention for each metric, and reading one as the other turns every
ranking upside down.

Chroma calls the metric a **space** and offers three: `cosine`, `ip` (inner product) and `l2`. The
program below copies the forty vectors into two more collections, one with no configuration and
one in the `ip` space, and asks all three the same question:

```schooling-example
{
  "language": "python",
  "file": "distances.py",
  "parts": [
    {
      "code": "import chromadb\nfrom minilm import embed\n\nclient = chromadb.PersistentClient(path=\"chroma\")\ncos = client.get_collection(\"help\")\neverything = cos.get(include=[\"documents\", \"embeddings\"])",
      "note": "Open the cosine collection and take everything out of it, vectors included."
    },
    {
      "code": "l2 = client.create_collection(\"help_l2\")\nip = client.create_collection(\"help_ip\", configuration={\"hnsw\": {\"space\": \"ip\"}})\nfor c in (l2, ip):\n    c.add(ids=everything[\"ids\"], embeddings=everything[\"embeddings\"],\n          documents=everything[\"documents\"])\n    print(c.name, \"space:\", c.configuration[\"hnsw\"][\"space\"])",
      "note": "Two more collections with the same vectors and texts: one with no configuration and one in the `ip` space. Passing `embeddings` skips the embedding function."
    },
    {
      "code": "q = embed(\"how do I get my money back\")[0]\nfor c in (cos, ip, l2):\n    r = c.query(query_embeddings=[q], n_results=3)\n    print(f\"{c.name:8}\", \"  \".join(f\"{i} {d:.4f}\" for i, d in zip(r[\"ids\"][0], r[\"distances\"][0])))",
      "note": "One query vector against the three collections, top three each."
    },
    {
      "code": "vec = dict(zip(everything[\"ids\"], everything[\"embeddings\"]))\nprint(f\"{'dot':8}\", \"  \".join(f\"{i} {float(vec[i] @ q):.4f}\" for i in r[\"ids\"][0]))",
      "note": "And the plain dot product of the query with each of those articles, the similarity lesson 2 built."
    }
  ],
  "output": "ana@lab:~/emb$ python distances.py\nhelp_l2 space: l2\nhelp_ip space: ip\nhelp     h18 0.5544  h15 0.5624  h22 0.6006\nhelp_ip  h18 0.5544  h15 0.5624  h22 0.6006\nhelp_l2  h18 1.1089  h15 1.1249  h22 1.2013\ndot      h18 0.4456  h15 0.4376  h22 0.3994"
}
```

Take h18, collection by collection:

| | value | how it relates to the dot product 0.4456 |
|---|---|---|
| `cosine` | 0.5544 | 1 − 0.4456 |
| `ip` | 0.5544 | 1 − 0.4456 |
| `l2` | 1.1089 | 2 − 2 × 0.4456 |

**The cosine distance is one minus the similarity**, so 0 means the same direction and 2 the
opposite one. The `ip` space returns one minus the dot product, which for unit vectors is the same
number, as lesson 2 showed. And **`l2` is the squared Euclidean distance**, not the distance itself:
for unit vectors lesson 2's ‖a − b‖² = 2 − 2 cos gives 2 − 2 × 0.4456 = 1.1088, which is Chroma's
1.1089 short of a rounding in the last digit. The square root of it appears nowhere.

The three rankings are identical, because all three are the same comparison on unit vectors. The
numbers are not, and that is where the trouble starts.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Three number lines for the same three help articles, h18, h15 and h22, against the question how do I get my money back. On the similarity line, from 0 to 1, they sit near 0.4 and higher is closer. On the cosine distance line, from 0 to 2, they sit near 0.56 to 0.60 and lower is closer; a cut-off at 0.6 keeps h18 and h15. On the squared L2 line, from 0 to 4, they sit near 1.1 to 1.2, and the same cut-off at 0.6 keeps none of them.\"><text x=\"60\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">similarity (dot product)</text><text x=\"660\" y=\"26\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">higher is closer</text><path d=\"M60 60 L660 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 55 L60 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M660 55 L660 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><circle cx=\"327.4\" cy=\"60\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"322.6\" cy=\"60\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"299.6\" cy=\"60\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"337.4\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">h18 0.4456 h15 0.4376 h22 0.3994</text><text x=\"60\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">cosine distance = 1 − similarity</text><text x=\"660\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lower is closer</text><path d=\"M60 170 L660 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 165 L60 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M360 165 L360 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M660 165 L660 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><circle cx=\"226.3\" cy=\"170\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"228.7\" cy=\"170\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"240.2\" cy=\"170\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"250.2\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">h18 0.5544 h15 0.5624 h22 0.6006</text><path d=\"M240 148 L240 196\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"234\" y=\"204\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cut-off 0.6: keeps two</text><text x=\"60\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">l2, squared = 2 − 2 × similarity</text><text x=\"660\" y=\"246\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lower is closer</text><path d=\"M60 280 L660 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 275 L60 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M210 275 L210 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"210\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M360 275 L360 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M510 275 L510 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"510\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M660 275 L660 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><circle cx=\"226.3\" cy=\"280\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"228.7\" cy=\"280\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"240.2\" cy=\"280\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"250.2\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">h18 1.1089 h15 1.1249 h22 1.2013</text><path d=\"M150 258 L150 306\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"156\" y=\"314\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cut-off 0.6: keeps none</text></svg>", "caption": "The same three articles on three scales. The ranking never changes; the numbers, and which way is better, do. A cut-off of 0.6 written for cosine distance keeps two of them; on the l2 scale it keeps none."}
```

## A cut-off belongs to one space

Suppose Marginalia decides to show an article only when it is close enough, and somebody writes
`distance < 0.6` after testing on the cosine collection. Two of the three articles above pass. Run
the same code on a collection created without a configuration, which is `l2` by default, and none
passes: the best of them is at 1.1089. Nothing errors; the help centre simply stops answering.

Lesson 16 is about choosing a cut-off at all. The lesson here is narrower: **a threshold is a number
in one space, from one model**, and it has to be stored with them.

## The space is fixed when the collection is made

There is no switching a collection to another space once it exists:

```python
import chromadb

col = chromadb.PersistentClient(path="chroma").get_collection("help")
try:
    col.modify(configuration={"hnsw": {"space": "l2"}})
except Exception as e:
    print(type(e).__name__ + ":", e)
```

```
ana@lab:~/emb$ python space.py
InvalidArgumentError: unknown field `space`, expected one of `ef_search`, `max_neighbors`, `num_threads`, `resize_factor`, `sync_threshold`, `batch_size` at line 1 column 17
```

The list of fields Chroma will change names search and maintenance settings and leaves out `space`,
because the index was built with that metric and every stored link between neighbours was measured
with it. A different space is a new collection and every vector added again, which is why
`distances.py` had to copy the forty vectors rather than flip a setting. Choose at creation, and for
a model that returns unit vectors, as all-MiniLM-L6-v2 does, choose `cosine`: the ranking is the same
as `ip`, and the numbers mean what lesson 2 taught.
