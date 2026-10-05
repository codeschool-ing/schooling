#!/usr/bin/env python3
"""The price sheet every embedding price in this course comes from.

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
