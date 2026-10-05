---
title: Three providers side by side
version: 1
---

Choosing between providers by reading their pages is choosing between three formats of the same
facts. The facts that decide most of it are four: **what a million tokens cost, how many numbers a
vector has, how long a text may be, and what the API lets you say about the text.** The first three
are on one sheet.

The providers' own pricing pages could not be reached from the machine this course was recorded on.
`prices.py` reads instead **LiteLLM's price sheet at commit b9e71e990aed**, a list an open-source
project keeps of every provider's prices and limits. It is a third party's copy, pinned so that it
reads the same next year; the providers' prices may not.

```
ana@lab:~/emb$ python3 prices.py
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

`compare.py` keeps the three providers of lessons 7 and 8 and adds three columns. One is the bytes
a float32 vector takes at the sheet's dimension. Another is the bill for embedding a million
documents of 500 tokens each, which is half a billion tokens. The last is the gigabytes their
million vectors take.

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "from prices import rows\n\nTOKENS = 1_000_000 * 500\nprint(f\"{'model':28} {'USD/MTok':>8} {'dims':>5} {'max in':>7} {'bytes':>6} {'500M tokens':>12} {'1M vecs GB':>10}\")\nfor r in rows():\n    if r[\"provider\"] not in (\"openai\", \"gemini\", \"cohere\"):\n        continue\n    dims = r[\"dims\"] or \"-\"\n    size = r[\"dims\"] * 4 if r[\"dims\"] else \"-\"\n    gb = f\"{r['dims'] * 4 * 1e6 / 1e9:.2f}\" if r[\"dims\"] else \"-\"\n    cost = TOKENS / 1e6 * r[\"usd_per_mtok\"]\n    print(f\"{r['model']:28} {r['usd_per_mtok']:8.3f} {dims:>5} {r['max_input_tokens']:>7} {size:>6} {cost:12.2f} {gb:>10}\")",
      "note": "`rows()` is the sheet as a list of dictionaries. Keep the three providers of these two lessons, and work out three columns from the sheet's own numbers: four bytes per dimension, the price times 500 million tokens, and a million vectors in gigabytes."
    }
  ],
  "output": "ana@lab:~/emb$ python compare.py\nmodel                        USD/MTok  dims  max in  bytes  500M tokens 1M vecs GB\ntext-embedding-3-small          0.020  1536    8191   6144        10.00       6.14\ntext-embedding-3-large          0.130  3072    8191  12288        65.00      12.29\ntext-embedding-ada-002          0.100  1536    8191   6144        50.00       6.14\ngemini/gemini-embedding-001     0.150  3072    2048  12288        75.00      12.29\ncohere/embed-v4.0               0.120  1536  128000   6144        60.00       6.14\nembed-english-v3.0              0.100     -     512      -        50.00          -\nembed-multilingual-v3.0         0.100     -     512      -        50.00          -"
}
```

## Reading the table

**The embedding bill is paid once; the bytes are paid for as long as the collection exists.** Half a
billion tokens cost 10.00 dollars with text-embedding-3-small and 75.00 with gemini-embedding-001.
Their vectors take 6,144 and 12,288 bytes, and a million of them 6.14 and 12.29 GB before any index:
held in memory by most indexes, read by every search, and stored twice while a model is being
replaced. Lesson 18 puts both on one bill.

**A dimension is a default, not a fixed cost.** The sheet lists the largest size for each model.
text-embedding-3 and gemini-embedding-001 both accept a smaller one, as lesson 7 and this lesson
showed, and Cohere documents 256, 512, 1,024 and 1,536 for embed-v4.0. A model at 3,072 can be
stored at 768 if your own measurement says the loss is acceptable, and that measurement is the one
from lesson 7 run on your data.

**The limit on input decides how you cut documents.** gemini-embedding-001 reads 2,048 tokens and
the two Cohere v3 models 512; the OpenAI models read 8,191 and embed-v4.0 128,000. A text longer than
the limit is cut off or refused, depending on the provider and the settings, and either way the end
of it is not in the vector. `rag` is the course that decides chunk sizes; the limit is where its
upper bound comes from.

**Blank cells are blanks in the sheet, not zeros.** The sheet has no dimension for Cohere's v3
models; Cohere documents 1,024 for both. Only two of OpenAI's models have a batch price on it.

## What the sheet cannot say

The four facts are not the whole choice. **Whether the model knows your language** is the first
of the rest: lesson 1 measured an English model scoring a Portuguese title as unrelated, and three
of the help centre's 40 articles are in Portuguese. embed-multilingual-v3.0 is named for exactly that, and
gemini-embedding-001 is documented as multilingual. **Whether it helps your search** is the second,
and only a measurement on your own questions answers it, the one this lesson ran in `search.py`
and `quantised.py`. And whether the data may leave the building at all is the question lesson 9
starts from.

The fourth fact on the first list, what each API lets you say about the text, is the one lesson 7 and
this lesson met call by call:

| | OpenAI | Google | Cohere |
|---|---|---|---|
| says what the text is for | no | `task_type`, optional | `input_type`, required |
| smaller dimension on request | `dimensions` | `output_dimensionality` | `output_dimension` (embed-v4.0) |
| integer and binary outputs | no | no | `embedding_types` |
