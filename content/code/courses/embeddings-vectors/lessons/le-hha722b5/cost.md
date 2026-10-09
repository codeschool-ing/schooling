---
title: What it costs
version: 1
---

An embedding API bills **input tokens only**. There is no answer to pay for beyond the vector, and
the vector is priced by the length of the text that went in. So the cost of embedding anything is
one multiplication: tokens times the price per token.

## The prices, from one sheet

OpenAI's own pricing page could not be reached from the machine this course was recorded on. The
prices here come from **LiteLLM's sheet at commit b9e71e990aed**, a list of providers' prices that
an open-source project keeps, read at a pinned commit so that the same numbers come out next year.
Save this as `~/emb/prices.py`:

```python
"""prices: the price sheet every embedding price in this course comes from.

ONE SOURCE, READ AT ONE PINNED COMMIT. LiteLLM's
model_prices_and_context_window.json is a list of prices and limits that an
open-source project keeps for every provider. It is a third party's copy of the
providers' own pages, which could not be reached from the machine this course
was recorded on, and the lessons say so beside every number. Pinning the commit
means the same sheet comes out next year; the providers' prices may not be the
same next year, and that is why the lessons quote the commit.

    python3 prices.py              # the sheet
    python3 prices.py --json       # the same rows, for a program to read

Standard library only. Prices are US dollars per million input tokens (MTok);
an embedding model has no output tokens to bill.
"""
import json
import os
import sys
import urllib.request

COMMIT = "b9e71e990aedac89a8cf5da2a47aca51abe37076"
URL = ("https://raw.githubusercontent.com/BerriAI/litellm/" + COMMIT
       + "/model_prices_and_context_window.json")
CACHE = os.path.expanduser("~/.cache/emb-prices")

# The sheet's own keys, in the order the lessons discuss them.
MODELS = [
    "text-embedding-3-small",
    "text-embedding-3-large",
    "text-embedding-ada-002",
    "gemini/gemini-embedding-001",
    "cohere/embed-v4.0",
    "embed-english-v3.0",
    "embed-multilingual-v3.0",
    "voyage/voyage-3.5",
    "voyage/voyage-3.5-lite",
    "mistral/mistral-embed",
]


def sheet():
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, COMMIT + ".json")
    if not os.path.exists(path):
        req = urllib.request.Request(URL, headers={"User-Agent": "curl/8.5.0"})
        with urllib.request.urlopen(req) as r, open(path + ".part", "wb") as f:
            f.write(r.read())
        os.rename(path + ".part", path)
    return json.load(open(path))


def rows():
    d = sheet()
    out = []
    for k in MODELS:
        v = d[k]
        per = v.get("input_cost_per_token")
        batch = v.get("input_cost_per_token_batches")
        out.append({
            "model": k,
            "provider": v.get("litellm_provider"),
            "usd_per_mtok": round(per * 1e6, 4) if per is not None else None,
            "batch_usd_per_mtok": round(batch * 1e6, 4) if batch is not None else None,
            "dims": v.get("output_vector_size"),
            "max_input_tokens": v.get("max_input_tokens"),
        })
    return out


def main():
    r = rows()
    if "--json" in sys.argv:
        json.dump(r, sys.stdout, indent=1)
        print()
        return
    print(f"LiteLLM price sheet at commit {COMMIT[:12]}, USD per million input tokens")
    print(f"{'model':30} {'provider':28} {'USD/MTok':>9} {'batch':>7} {'dims':>5} {'max in':>7}")
    for x in r:
        f = lambda v, w, p=None: (f"{v:>{w}.{p}f}" if p is not None else f"{v:>{w}}") if v is not None else f"{'-':>{w}}"
        print(f"{x['model']:30} {x['provider']:28} {f(x['usd_per_mtok'], 9, 3)} "
              f"{f(x['batch_usd_per_mtok'], 7, 3)} {f(x['dims'], 5)} {f(x['max_input_tokens'], 7)}")


if __name__ == "__main__":
    main()
```

It needs nothing beyond Python itself. The first run downloads the sheet from GitHub into
`~/.cache/emb-prices`, and every run after that reads the copy, so the numbers stay put even if
the sheet moves on:

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

Prices are in US dollars per million tokens. The **batch** column is the price through OpenAI's
Batch API, where you upload a file of requests and collect the results later, within a day. The
sheet lists it at half the ordinary price for the two text-embedding-3 models and has no batch
price for ada-002. The Batch API was not run here; labembed does not imitate it.

Prices change. A sheet at a pinned commit is a fixed point you can check a calculation against,
not a quote: before committing to a budget, read the provider's own page on the day.

## The help centre, and a million documents

```schooling-example
{
  "language": "python",
  "file": "cost.py",
  "parts": [
    {
      "code": "import json\nimport tiktoken\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\ntokens = sum(len(enc.encode(h[\"title\"] + \". \" + h[\"body\"])) for h in help)\nprices = {p[\"model\"]: p for p in json.load(open(\"prices.json\"))}\nprint(\"help centre:\", tokens, \"tokens\")",
      "note": "Count the help centre's tokens with `cl100k_base`, and read the prices that `prices.py --json` wrote."
    },
    {
      "code": "for name in (\"text-embedding-3-small\", \"text-embedding-3-large\", \"text-embedding-ada-002\"):\n    p = prices[name]\n    batch = p[\"batch_usd_per_mtok\"]\n    print(f\"{name:23}  help centre ${tokens * p['usd_per_mtok'] / 1e6:.6f}\"\n          f\"  a million 500-token documents ${500 * p['usd_per_mtok']:,.2f}\"\n          + (f\" (batch ${500 * batch:,.2f})\" if batch else \"\"))",
      "note": "For each OpenAI model on the sheet: the help centre once, and a million documents of 500 tokens each, which is 500 million tokens. The batch price is printed where the sheet has one."
    }
  ]
}
```

```
ana@lab:~/emb$ python3 prices.py --json > prices.json
ana@lab:~/emb$ python cost.py
help centre: 2205 tokens
text-embedding-3-small   help centre $0.000044  a million 500-token documents $10.00 (batch $5.00)
text-embedding-3-large   help centre $0.000287  a million 500-token documents $65.00 (batch $32.50)
text-embedding-ada-002   help centre $0.000220  a million 500-token documents $50.00
```

**The whole help centre costs a few thousandths of a cent** with text-embedding-3-small. That is
worth knowing for one reason: re-embedding a small corpus is never the expensive part of changing
a model. The expensive parts are elsewhere, and lesson 18 counts them.

A million documents of 500 tokens is half a billion tokens, which costs $10.00 with the small model,
$65.00 with the large one, and half of either through the Batch API. Two things make real bills
larger than this arithmetic. Documents are usually split into overlapping chunks, so the same text
is embedded more than once. And every question a user types is embedded too, so a busy search box
keeps billing after the documents are done, a few tokens at a time.

The first is under your control and the second is cheap per call. Neither changes the method:
count tokens with the provider's tokeniser, multiply by the price on the day, and keep the count
from `usage` to check the bill against.
