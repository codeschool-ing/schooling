---
title: Two ways to pay
version: 1
---

A closed model is paid for **per token**, to the provider or to a cloud that resells it. An open
model can be paid for the same way, to any of the companies that host it, or **per hour**, for a
machine you run it on yourself. Lesson 3 is about the second. This section is about what the first
looks like for each kind, read off the sheet.

## The sheet

Every provider publishes its prices on its own page, in its own format. **LiteLLM**, an open-source
library that calls a hundred providers through one interface, keeps all of them in one JSON file,
so that it can price the calls it makes. That file is the sheet this course reads: a third party's
copy of the providers' pages. Every number taken from it says so, and it is read at one commit, so
the same numbers come out next year. `sheet.py` downloads it once, keeps it
beside itself in `~/desk`, and answers eight questions about it:

```python
"""sheet.py: the model catalogue every number in ai-models comes from.

LiteLLM is an open-source library that calls a hundred model providers through
one interface, and to price their calls it keeps a file of every model it
knows: its window, its output ceiling, its price per token, and what it
supports. This reads that file at ONE PINNED COMMIT, so the same sheet comes
out next year, and keeps it beside the program after the first download.

    python sheet.py count                         entries per provider
    python sheet.py provider NAME [--mode chat]   one provider's models
    python sheet.py where TEXT                    every entry whose name contains TEXT
    python sheet.py show NAME                     everything the sheet says about one
    python sheet.py compare NAME...               one row per named entry, in that order
    python sheet.py cost NAME IN OUT              what IN input and OUT output tokens cost
    python sheet.py retiring [--provider P]       entries with a deprecation date, soonest first
    python sheet.py pick [--provider P] [--min-window N] [--needs a,b] [--max-in X]
                                                  filter, then sort by input price; an entry
                                                  priced 0 is left out, because the sheet
                                                  writes 0 for free AND for unknown

Prices are dollars per million tokens (MTok). Standard library only.
"""
import argparse
import json
import os
import signal
import sys
import urllib.request
from collections import Counter
from decimal import Decimal

COMMIT = "21881c571181fc0e409dd717b8a277e5b43152a7"
URL = ("https://raw.githubusercontent.com/BerriAI/litellm/" + COMMIT
       + "/model_prices_and_context_window.json")
CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "litellm-%s.json" % COMMIT[:8])
FLAGS = [("vision", "V"), ("function_calling", "F"), ("response_schema", "S"),
         ("prompt_caching", "C"), ("reasoning", "R"), ("pdf_input", "P")]


def load():
    if not os.path.exists(CACHE):
        with urllib.request.urlopen(URL) as r, open(CACHE + ".part", "wb") as f:
            f.write(r.read())
        os.rename(CACHE + ".part", CACHE)
    with open(CACHE) as f:
        d = json.load(f)
    d.pop("sample_spec", None)
    return d


def mtok(per_token):
    if per_token in (None, ""):
        return "-"
    v = Decimal(str(per_token)) * 1000000
    return f"{v.normalize():f}"


def flags(e):
    return "".join(c if e.get("supports_" + k) else "." for k, c in FLAGS)


def window(e):
    n = e.get("max_input_tokens")
    return f"{n:,}" if isinstance(n, int) else "-"


def table(rows):
    """V vision, F function calling, S response schema, C prompt caching, R reasoning, P PDF input."""
    print(f"{'model':44} {'window':>10} {'max out':>8} {'in $/M':>8} {'out $/M':>8}  VFSCRP")
    for k, e in rows:
        out = e.get("max_output_tokens")
        print(f"{k[:44]:44} {window(e):>10} {out if isinstance(out, int) else '-':>8} "
              f"{mtok(e.get('input_cost_per_token')):>8} {mtok(e.get('output_cost_per_token')):>8}  {flags(e)}")


def main():
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # a pipe into head is not an error
    p = argparse.ArgumentParser(prog="sheet.py")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("count")
    a = sub.add_parser("provider"); a.add_argument("name"); a.add_argument("--mode", default="chat")
    a = sub.add_parser("where"); a.add_argument("text")
    a = sub.add_parser("show"); a.add_argument("name")
    a = sub.add_parser("compare"); a.add_argument("names", nargs="+")
    a = sub.add_parser("cost"); a.add_argument("name"); a.add_argument("tin", type=int); a.add_argument("tout", type=int)
    a = sub.add_parser("retiring"); a.add_argument("--provider"); a.add_argument("--mode", default="chat")
    a = sub.add_parser("pick")
    a.add_argument("--provider"); a.add_argument("--min-window", type=int, default=0)
    a.add_argument("--needs", default=""); a.add_argument("--max-in", type=Decimal)
    a.add_argument("--top", type=int, default=12)
    args = p.parse_args()
    d = load()
    print(f"# LiteLLM model sheet at {COMMIT[:8]}, {len(d)} entries")
    if args.cmd == "count":
        c = Counter(e.get("litellm_provider") for e in d.values())
        for name, n in c.most_common(int(os.environ.get("SHEET_TOP", "15"))):
            print(f"{n:5}  {name}")
        print(f"{len(c):5}  providers in all")
    elif args.cmd == "provider":
        rows = [(k, e) for k, e in d.items()
                if e.get("litellm_provider") == args.name and e.get("mode") == args.mode]
        table(sorted(rows))
    elif args.cmd == "where":
        rows = [(k, e) for k, e in d.items() if args.text in k]
        print(f"{'entry':52} {'provider':26} {'in $/M':>8} {'out $/M':>8}")
        for k, e in sorted(rows, key=lambda r: (r[1].get("litellm_provider", ""), r[0])):
            print(f"{k[:52]:52} {e.get('litellm_provider', '')[:26]:26} "
                  f"{mtok(e.get('input_cost_per_token')):>8} {mtok(e.get('output_cost_per_token')):>8}")
    elif args.cmd == "show":
        if args.name not in d:
            sys.exit(f"sheet.py: no entry named {args.name}")
        for k, v in sorted(d[args.name].items()):
            print(f"{k:42} {v}")
    elif args.cmd == "compare":
        missing = [n for n in args.names if n not in d]
        if missing:
            sys.exit("sheet.py: no entry named " + ", ".join(missing))
        table([(n, d[n]) for n in args.names])
    elif args.cmd == "cost":
        e = d[args.name]
        cin = Decimal(str(e["input_cost_per_token"])) * args.tin
        cout = Decimal(str(e["output_cost_per_token"])) * args.tout
        print(f"{args.tin:,} in  x ${mtok(e['input_cost_per_token'])}/M = ${cin:.4f}")
        print(f"{args.tout:,} out x ${mtok(e['output_cost_per_token'])}/M = ${cout:.4f}")
        print(f"total ${cin + cout:.4f}")
    elif args.cmd == "retiring":
        rows = [(e["deprecation_date"], k, e.get("litellm_provider", "")) for k, e in d.items()
                if e.get("deprecation_date") and e.get("mode") == args.mode
                and (not args.provider or e.get("litellm_provider") == args.provider)]
        print(f"{len(rows)} entries carry a deprecation date")
        for date, k, prov in sorted(rows):
            print(f"{date}  {k[:50]:50} {prov}")
    elif args.cmd == "pick":
        needs = [n for n in args.needs.split(",") if n]
        rows = []
        for k, e in d.items():
            if e.get("mode") != "chat" or not isinstance(e.get("input_cost_per_token"), (int, float)):
                continue
            if args.provider and e.get("litellm_provider") != args.provider:
                continue
            if not e["input_cost_per_token"]:
                continue  # a price of 0 in the sheet is free or unknown, and is neither a price
            if not isinstance(e.get("max_input_tokens"), int) or e["max_input_tokens"] < args.min_window:
                continue
            if any(not e.get("supports_" + n) for n in needs):
                continue
            if args.max_in is not None and Decimal(str(e["input_cost_per_token"])) * 1000000 > args.max_in:
                continue
            rows.append((k, e))
        print(f"{len(rows)} entries pass")
        table(sorted(rows, key=lambda r: (r[1]["input_cost_per_token"], r[0]))[:args.top])


if __name__ == "__main__":
    main()
```

It uses nothing but Python's standard library, and the first run takes a few seconds longer while it
downloads the file. Every table it prints starts with the commit and the number of entries,
so a number quoted from it says where it came from.

`python sheet.py where` lists every entry whose name contains a string. Here is one open model,
Llama 3.3 70B, and every host that the sheet prices:

```
ana@desk:~/desk$ python sheet.py where llama-3.3-70b
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
cerebras/llama-3.3-70b                               cerebras                       0.85      1.2
cloudflare/@cf/meta/llama-3.3-70b-instruct-fp8-fast  cloudflare                    0.293    2.253
novita/meta-llama/llama-3.3-70b-instruct             novita                        0.135      0.4
oci/meta.llama-3.3-70b-instruct                      oci                            0.72     0.72
oci/meta.llama-3.3-70b-instruct-fp8-dynamic          oci                            0.72     0.72
openrouter/meta-llama/llama-3.3-70b-instruct         openrouter                     0.22      0.5
scaleway/meta/llama-3.3-70b-instruct                 scaleway                        0.9      0.9
snowflake/snowflake-llama-3.3-70b                    snowflake                      0.72     0.72
vercel_ai_gateway/meta/llama-3.3-70b                 vercel_ai_gateway              0.72     0.72
vertex_ai/meta/llama-3.3-70b-instruct-maas           vertex_ai-llama_models         0.72     0.72
```

Ten entries from nine providers, and the cheapest input price is **$0.135** a million tokens against
**$0.90** at the dearest: almost seven times as much for the same weights. The output prices run
from $0.40 to $2.253. Some of the difference is real: `fp8` in a name means the host runs the
weights at reduced precision, which lesson 3 explains, and the hosts differ in speed and in what
they promise about availability. But a large part of it is **competition**. Anybody with the
hardware may serve these weights, so they do, and the price falls towards the cost of the machine.

Now a closed model, Claude Sonnet 5.5:

```
ana@desk:~/desk$ python sheet.py where claude-sonnet-5-5
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
claude-sonnet-5-5                                    anthropic                         2       10
azure_ai/claude-sonnet-5-5                           azure_ai                          2       10
bedrock/us-gov-east-1/anthropic.claude-sonnet-5-5    bedrock                         2.4       12
bedrock/us-gov-west-1/anthropic.claude-sonnet-5-5    bedrock                         2.4       12
anthropic.claude-sonnet-5-5                          bedrock_converse                  2       10
apac.anthropic.claude-sonnet-5-5                     bedrock_converse                2.2       11
au.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
eu.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
global.anthropic.claude-sonnet-5-5                   bedrock_converse                  2       10
jp.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
us-gov.anthropic.claude-sonnet-5-5                   bedrock_converse                2.4       12
us.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
bedrock_mantle/anthropic.claude-sonnet-5-5           bedrock_mantle                  2.2       11
bedrock_mantle/us-gov-west-1/anthropic.claude-sonnet bedrock_mantle                  2.4       12
perplexity/anthropic/claude-sonnet-5-5               perplexity                        2       10
vertex_ai/claude-sonnet-5-5                          vertex_ai-anthropic_models        2       10
vertex_ai/claude-sonnet-5-5@default                  vertex_ai-anthropic_models        2       10
```

Seventeen entries, and every one is Anthropic's model resold, or reached through Anthropic's own
API. The prices barely move: **$2** in and **$10** out at Anthropic itself, at Azure, at Google's
Vertex and on Bedrock's `global` route; ten per cent more on Bedrock's regional routes, twenty per
cent more for the US government regions. No host can undercut the maker, because no host has
anything to sell but access to the maker's model.

## What that means for choosing

- **An open model is a commodity, and a commodity is shopped for.** The model is fixed; choose
  the host for price, speed and terms, and change host without changing a line of the prompt.
  Lesson 15 shows a router that does the shopping per request.
- **A closed model has one price**, set by the people who made it, with small regional
  differences. What you negotiate is volume, not the per-token rate on the page.
- **Per token is never the whole bill.** It is the part that scales with use. Lesson 4 adds the
  other parts, and lesson 21 the ones that only show up when something goes wrong.

The sheet is a third party's copy taken at one commit, and both lists will have moved by the time
you read this. **The shape is what lasts**: many hosts and a wide spread for open weights, one
maker and a narrow band for closed ones.
