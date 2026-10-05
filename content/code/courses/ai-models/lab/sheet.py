#!/opt/aimodels/bin/python
"""sheet: the model catalogue every number in this course's lessons comes from.

IT IS A THIRD PARTY'S COPY, READ AT ONE PINNED COMMIT. LiteLLM is an
open-source library that calls a hundred model providers through one
interface, and to price their calls it keeps a file of every model it knows:
its window, its output ceiling, its price per token, and what it supports.
The providers' own pages could not be reached from the machine this course was
recorded on; this file could. So it is the source, the lessons say so beside
every number they take from it, and the commit is pinned so the same sheet
comes out next year.

    sheet count                         entries per provider
    sheet provider NAME [--mode chat]   one provider's models
    sheet where TEXT                    every entry whose name contains TEXT
    sheet show NAME                     everything the sheet says about one
    sheet compare NAME...               one row per named entry, in that order
    sheet cost NAME IN OUT              what IN input and OUT output tokens cost
    sheet retiring [--provider P]       entries with a deprecation date, soonest first
    sheet pick [--provider P] [--min-window N] [--needs a,b] [--max-in X]
                                        filter, then sort by input price; an
                                        entry priced 0 is left out, because
                                        the sheet writes 0 for free AND unknown

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
CACHE = os.environ.get("SHEET_CACHE", "/opt/aimodels/share/litellm-%s.json" % COMMIT[:8])
FLAGS = [("vision", "V"), ("function_calling", "F"), ("response_schema", "S"),
         ("prompt_caching", "C"), ("reasoning", "R"), ("pdf_input", "P")]


def load():
    if not os.path.exists(CACHE):
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
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
    p = argparse.ArgumentParser(prog="sheet")
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
            sys.exit(f"sheet: no entry named {args.name}")
        for k, v in sorted(d[args.name].items()):
            print(f"{k:42} {v}")
    elif args.cmd == "compare":
        missing = [n for n in args.names if n not in d]
        if missing:
            sys.exit("sheet: no entry named " + ", ".join(missing))
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
