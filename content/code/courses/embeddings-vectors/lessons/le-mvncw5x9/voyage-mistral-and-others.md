---
title: Voyage, Mistral and the rest of the sheet
version: 1
---

OpenAI, Google and Cohere are the providers most people meet first, and they are a small part of
what is for sale. The sheet this course quotes prices from lists far more embedding models than
lessons 7 and 8 used. Reading it is a quick way to see the shape of the market: who sells general
models, who sells models for one kind of text, and who sells somebody else's open model by the
token.

The bottom of `prices.py`, which lesson 7 ran, has the two names this lesson's title promises:

```
ana@lab:~/emb$ python prices.py
LiteLLM price sheet at commit b9e71e990aed, USD per million input tokens
model                          provider                      USD/MTok   batch  dims  max in
text-embedding-3-small         openai                           0.020   0.010  1536    8191
text-embedding-3-large         openai                           0.130   0.065  3072    8191
text-embedding-ada-002         openai                           0.100       -  1536    8191
gemini/gemini-embedding-001    gemini                           0.150       -  3072    2048
cohere/embed-v4.0              cohere                           0.120       -  1536  128000
embed-english-v3.0             cohere                           0.100       -     -     512
embed-multilingual-v3.0        cohere                           0.100       -     -     512
voyage/voyage-3.5              voyage                           0.060       -     -   32000
voyage/voyage-3.5-lite         voyage                           0.020       -     -   32000
mistral/mistral-embed          mistral                          0.100       -     -    8192
```

**Voyage AI sells `voyage-3.5` at 0.060 dollars per million tokens and `voyage-3.5-lite` at 0.020**,
the same as `text-embedding-3-small`. Mistral's `mistral-embed` is at 0.100. Both read long inputs:
32000 tokens for Voyage and 8192 for Mistral, far more than the word pieces lesson 9 found
all-MiniLM-L6-v2 reads.

**A dash is a gap in the sheet, not a zero.** The `dims` column is empty for both providers because
the sheet does not record their dimension, and `batch` is empty because it records no discounted
batch price for them. Neither means the thing is absent. A missing value on a third party's sheet is
a question for the provider's own documentation. So is Voyage's request shape, which takes an
`input_type` of `query` or `document` like Cohere's in lesson 8. Neither provider's SDK is installed
in the lab and neither API was reachable, so none of their code appears here.

## What else the sheet holds

`prices.py` shows ten rows because the course picked ten. The sheet has many more, and `sheet.py`
reads it directly through the same function:

```schooling-example
{
  "language": "python",
  "file": "sheet.py",
  "parts": [
    {
      "code": "from prices import sheet\n\nd = sheet()\nemb = [k for k, v in d.items() if v.get(\"mode\") == \"embedding\"]\nprint(\"embedding rows:\", len(emb))\nprint(\"rows naming jina:\", [(k, v[\"mode\"]) for k, v in d.items() if \"jina\" in k])",
      "note": "`sheet()` is the function `prices.py` uses to read LiteLLM's sheet at the pinned commit. Count the rows whose mode is `embedding`, and list every row whose name contains `jina`, whatever its mode."
    },
    {
      "code": "rows = [\"voyage/voyage-code-3\", \"voyage/voyage-law-2\", \"voyage/voyage-finance-2\",\n        \"mistral/codestral-embed\", \"fireworks_ai/nomic-ai/nomic-embed-text-v1.5\",\n        \"together_ai/BAAI/bge-base-en-v1.5\", \"novita/baai/bge-m3\"]\nfor k in rows:\n    v = d[k]\n    usd = v[\"input_cost_per_token\"] * 1e6\n    dims = v.get(\"output_vector_size\") or \"-\"\n    print(f\"{k:44} {usd:6.3f} {dims:>5} {v['max_input_tokens']:>6}\")",
      "note": "Seven rows `prices.py` does not show: four models trained for one kind of text and three open models sold by hosting companies. Price in dollars per million tokens, dimension, maximum input in tokens."
    }
  ]
}
```

```
ana@lab:~/emb$ python sheet.py
embedding rows: 149
rows naming jina: [('jina-reranker-v2-base-multilingual', 'rerank')]
voyage/voyage-code-3                          0.180     -  32000
voyage/voyage-law-2                           0.120     -  16000
voyage/voyage-finance-2                       0.120     -  32000
mistral/codestral-embed                       0.150     -   8192
fireworks_ai/nomic-ai/nomic-embed-text-v1.5   0.008     -   8192
together_ai/BAAI/bge-base-en-v1.5             0.008   768    512
novita/baai/bge-m3                            0.010     -   8192
```

**149 rows on the sheet are embedding models, and none of them is Jina's.** The one row that names
Jina is `jina-reranker-v2-base-multilingual`, and its mode says `rerank`: a model that rescores a
short list of results, which lesson 16 describes. That is why the previous section quotes no price
for Jina.

The rows the program picked fall into two groups, and each is a different kind of choice.

**Models trained for one kind of text.** Voyage sells `voyage-code-3`, `voyage-law-2` and
`voyage-finance-2`, and Mistral sells `codestral-embed`. They are sold on the claim that a model
trained on code, contracts or financial reports places those texts better than a general one. They
also cost more on this sheet: 0.180 for Voyage's code model against 0.060 for its general one.
Whether the claim holds for your texts is a measurement, made the way lesson 9 measured MiniLM
against WordLlama: on your own questions with your own judgements.

**Open models sold by the token.** `nomic-embed-text-v1.5` from Nomic, `bge-base-en-v1.5` and
`bge-m3` from BAAI are open models whose weights anybody can download, which lesson 9 is about.
Here they are sold by hosting companies, Fireworks, Together and Novita, for 0.008 to 0.010 dollars
per million tokens. That is the third option between paying a model's maker and running it
yourself: somebody else's machines, running weights you could also run. It keeps the model
portable, since the same weights are available if you leave the host. Whether two hosts' vectors
of the same model can be mixed depends on whether each runs it at the same precision, and that is a
question to ask the host before you mix them rather than after.

**The `bge-base-en-v1.5` row also shows what a short limit looks like on a price list**: 768
dimensions and 512 tokens of input. Cheap per token, and a long article has to be cut into pieces
before it fits.

None of these rows is a recommendation, and nothing in this section was measured. The last section
of this lesson, *Choosing a model*, says how to turn a list like this into a decision.
