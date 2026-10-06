"""costs.py: what each request cost, from the tokens on its spans and the price in force when it ran.

    import costs
    for r in costs.requests():      # one record per trace in spans.jsonl
        print(r["feature"], r["cost"])

Tokens are what the spans record; money is worked out here, at reading time,
from prices.json. A price is effective-dated: each model has a list of prices,
each from a date, and a span is charged the latest one whose date is not after
the moment it ran. Amounts are Decimal, never float.
"""
import json
from collections import defaultdict
from datetime import datetime
from decimal import Decimal

PRICES = json.load(open("prices.json"))
MILLION = Decimal(1_000_000)


def price_at(model, day):
    """(input, output) in dollars per million tokens for MODEL on DAY, an ISO date."""
    rows = [p for p in PRICES["models"].get(model, []) if p["from"] <= day]
    if not rows:
        raise LookupError(f"no price for {model} on {day}")
    p = max(rows, key=lambda p: p["from"])
    return Decimal(p["input"]), Decimal(p["output"])


def span_cost(s):
    """The cost of one span: zero unless it records tokens."""
    a = s["attributes"]
    if "gen_ai.usage.input_tokens" not in a:
        return Decimal(0)
    model = a.get("gen_ai.response.model") or a["gen_ai.request.model"]
    pin, pout = price_at(model, datetime.fromtimestamp(s["start"] / 1e9).date().isoformat())
    return (a["gen_ai.usage.input_tokens"] * pin + a.get("gen_ai.usage.output_tokens", 0) * pout) / MILLION


ROOT = {"app.feature": "feature", "app.release": "release", "app.outcome": "outcome",
        "user.hash": "user", "session.id": "session", "gen_ai.request.model": "model"}


def requests(path="spans.jsonl"):
    """One record per trace: its root's attributes, when it started, how long it took, its tokens, its cost."""
    by = defaultdict(list)
    for line in open(path):
        s = json.loads(line)
        by[s["trace"]].append(s)
    out = []
    for trace, spans in by.items():
        root = next(s for s in spans if s["parent"] is None)
        chats = [s for s in spans if s["attributes"].get("gen_ai.operation.name") == "chat"]
        out.append({"trace": trace, "at": datetime.fromtimestamp(root["start"] / 1e9),
                    "ms": (root["end"] - root["start"]) / 1e6, "status": root["status"],
                    **{short: root["attributes"].get(k) for k, short in ROOT.items()},
                    "input": sum(s["attributes"].get("gen_ai.usage.input_tokens", 0) for s in chats),
                    "output": sum(s["attributes"].get("gen_ai.usage.output_tokens", 0) for s in chats),
                    "cost": sum((span_cost(s) for s in spans), Decimal(0))})
    return sorted(out, key=lambda r: r["at"])
