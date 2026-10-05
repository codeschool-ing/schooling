---
title: Smaller vectors from the same call
version: 1
---

A float32 vector spends four bytes on every coordinate, and most of that precision does not change
which article ranks first. Cohere's endpoint can return the same vector in cheaper forms, chosen
with `embedding_types`, and **one call can ask for several**, so the comparison below costs one
request per model.

| `embedding_types` | each coordinate becomes | bytes for 384 numbers |
|---|---|---|
| `float` | a 32-bit float, as before | 1,536 |
| `int8` | a whole number from −128 to 127 | 384 |
| `uint8` | the same, shifted to 0 to 255 | 384 |
| `binary` | one bit, packed eight to a byte, as signed bytes | 48 |
| `ubinary` | the same bits, as unsigned bytes | 48 |

**These are labembed's encodings, written for this lab, and Cohere computes its own differently.**
The lab's int8 scales each vector so that its largest coordinate becomes 127 and rounds the rest;
its binary keeps one bit per coordinate, set when the number is above zero. So the numbers below
describe what quantisation does to these two models, and not what Cohere's encodings would score.

## Comparing in each encoding

Each encoding needs its own way to score. Floats and int8 are compared with a dot product, the int8
ones in 32-bit integers so the sums cannot overflow. Bits are compared by **Hamming distance**,
the number of positions where two bit strings differ: fewer differences means closer, so the
program negates it to keep *higher is closer*.

```schooling-example
{
  "language": "python",
  "file": "quantised.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nimport cohere\n\nco = cohere.ClientV2(api_key=os.environ[\"CO_API_KEY\"], base_url=os.environ[\"CO_API_URL\"])\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]\nKINDS = {\"float\": np.float32, \"int8\": np.int8, \"ubinary\": np.uint8}",
      "note": "The same setup, and the three encodings to ask for with the NumPy type each one is stored in."
    },
    {
      "code": "def embed(model, texts, input_type):\n    r = co.embed(model=model, texts=texts, input_type=input_type,\n                 embedding_types=list(KINDS))\n    e = r.embeddings\n    return {\"float\": np.array(e.float_, dtype=np.float32),\n            \"int8\": np.array(e.int8, dtype=np.int8),\n            \"ubinary\": np.array(e.ubinary, dtype=np.uint8)}",
      "note": "One call per list of texts asks for all three encodings, and each comes back as its own list. Each is kept in the NumPy type it fits."
    },
    {
      "code": "def scores(kind, Q, D):\n    if kind == \"ubinary\":\n        q, d = np.unpackbits(Q, axis=1), np.unpackbits(D, axis=1)\n        return -(q[:, None, :] != d[None, :, :]).sum(axis=2)\n    if kind == \"int8\":\n        return Q.astype(np.int32) @ D.astype(np.int32).T\n    return Q @ D.T",
      "note": "How to score each encoding: Hamming distance for bits, negated so higher is closer; a dot product in 32-bit integers for int8; a plain dot product for floats."
    },
    {
      "code": "print(f\"{'model':14} {'type':8} {'bytes':>5}  top 1  top 3  tied at 1\")\nfor model in [\"lab-minilm\", \"lab-wordllama\"]:\n    D = embed(model, [h[\"title\"] + \". \" + h[\"body\"] for h in help], \"search_document\")\n    Q = embed(model, [q[\"text\"] for q in queries], \"search_query\")\n    for kind in KINDS:\n        S = scores(kind, Q[kind], D[kind])\n        top = np.argsort(-S, axis=1, kind=\"stable\")[:, :3]\n        one = sum(ids[t[0]] in q[\"relevant\"] for t, q in zip(top, queries))\n        three = sum(any(ids[j] in q[\"relevant\"] for j in t) for t, q in zip(top, queries))\n        ties = sum(int(row[t[0]] == row[t[1]]) for row, t in zip(S, top))\n        print(f\"{model:14} {kind:8} {D[kind][0].nbytes:5}  {one:5}  {three:5}  {ties:9}\")",
      "note": "For each model and encoding, the bytes of one vector, the questions answered at rank 1 and in the top 3, and how many questions had two articles tied for first place."
    }
  ],
  "output": "ana@lab:~/emb$ python quantised.py\nmodel          type     bytes  top 1  top 3  tied at 1\nlab-minilm     float     1536     19     22          0\nlab-minilm     int8       384     18     22          0\nlab-minilm     ubinary     48     16     23          1\nlab-wordllama  float     1024     20     24          0\nlab-wordllama  int8       256     20     23          0\nlab-wordllama  ubinary     32     15     21          1"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Bars for the bytes one vector takes in each encoding, with how many of the 24 queries found a relevant article at rank 1 and in the top 3. lab-minilm float: 1536 bytes, 19 at rank 1, 22 in the top 3; lab-minilm int8: 384 bytes, 18 at rank 1, 22 in the top 3; lab-minilm ubinary: 48 bytes, 16 at rank 1, 23 in the top 3; lab-wordllama float: 1024 bytes, 20 at rank 1, 24 in the top 3; lab-wordllama int8: 256 bytes, 20 at rank 1, 23 in the top 3; lab-wordllama ubinary: 32 bytes, 15 at rank 1, 21 in the top 3.\"><text x=\"200\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bytes per vector</text><text x=\"628\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rank 1</text><text x=\"688\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">top 3</text><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">lab-minilm</text><text x=\"190\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">float</text><rect x=\"200\" y=\"59\" width=\"320\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"528\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1536</text><text x=\"630\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">19</text><text x=\"690\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">22</text><text x=\"190\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int8</text><rect x=\"200\" y=\"89\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"288\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">384</text><text x=\"630\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">18</text><text x=\"690\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">22</text><text x=\"190\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ubinary</text><rect x=\"200\" y=\"119\" width=\"10\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"218\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">48</text><text x=\"630\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">16</text><text x=\"690\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">23</text><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">lab-wordllama</text><text x=\"190\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">float</text><rect x=\"200\" y=\"185\" width=\"213.3\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"421.3\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1024</text><text x=\"630\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"690\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">24</text><text x=\"190\" y=\"224\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int8</text><rect x=\"200\" y=\"215\" width=\"53.3\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"261.3\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">256</text><text x=\"630\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"690\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">23</text><text x=\"190\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ubinary</text><rect x=\"200\" y=\"245\" width=\"6.7\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"214.7\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">32</text><text x=\"630\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">15</text><text x=\"690\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">21</text><path d=\"M600 34 L600 272\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">of 24 queries</text></svg>", "caption": "One request, three encodings of each vector. Bytes fall to a quarter with int8 and to a thirty-second with binary; the 24 queries barely notice int8, and binary costs WordLlama more than MiniLM. The encodings are labembed's arithmetic, not Cohere's."}
```

Read the MiniLM rows first. **int8 kept 22 of the 24 queries in the top 3 at a quarter of the
bytes**, and lost one at rank 1, 18 against 19. **Binary kept 23 in the top 3 at a thirty-second of
the bytes**, one more than float. That is not binary being better: with 24 questions, one query
moving is chance, and the honest reading of the MiniLM rows is that neither encoding cost anything
this measurement can see.

WordLlama is where the cost shows. Its binary vector has 256 bits, against MiniLM's 384, and it
dropped to 15 at rank 1 and 21 in the top 3, from 20 and 24. Fewer coordinates leave fewer bits to
carry the difference between two close articles.

The last column is a trap that bits set and floats do not. **A Hamming distance is a whole number**,
so two articles can tie exactly, and one query in each binary run had two articles tied at rank 1.
The program breaks ties by the order of the articles in the file, which is arbitrary; a real system
breaks them by rescoring.

## What it is for

A binary vector is cheap to keep and very cheap to compare, and its weakness is precision at the
top. The usual answer uses both: search everything with the bits, take the best few dozen, and
rescore only those with the float vectors. Lesson 15 meets quantisation inside an index, lesson 16
shows that rescoring, and lesson 18 prices the bytes. What this section established is narrower
and is the part a provider decides for you: **the encoding is chosen per request**, so the encoding a
collection was stored in decides how every later query has to be scored against it.
