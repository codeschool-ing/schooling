"""Check every price the publishers sent before it is loaded.

Each record is fixed where the fix is certain, rejected where it is not, and
counted either way. The good records go on to be loaded; the rejected ones go
to quarantine with the reason; and if too many are rejected, nothing is loaded."""
import json
import sys
from collections import Counter

MAX_REJECTED = 0.05          # more than 5% rejected: the batch is wrong, not the records


def isbn13_ok(isbn):
    """The last digit of an ISBN-13 is a check digit over the other twelve."""
    if len(isbn) != 13 or not isbn.isdigit():
        return False
    total = sum(int(d) * (3 if i % 2 else 1) for i, d in enumerate(isbn[:12]))
    return (10 - total % 10) % 10 == int(isbn[12])


def check(rec, fixed):
    """Return the reason to reject rec, or None; fix what can be fixed, in place."""
    if "-" in rec["isbn"]:
        rec["isbn"] = rec["isbn"].replace("-", "")
        fixed["isbn written with hyphens"] += 1
    if not isbn13_ok(rec["isbn"]):
        return "isbn fails its check digit"
    if rec["publisher"] != rec["publisher"].strip():
        rec["publisher"] = rec["publisher"].strip()
        fixed["publisher with stray spaces"] += 1
    if rec["currency"] != "BRL":
        if rec["currency"].upper() != "BRL":
            return f"currency {rec['currency']!r}"
        rec["currency"] = "BRL"
        fixed["currency in lower case"] += 1
    price = rec["list_price_cents"]
    if price is None:
        return "price missing"
    if isinstance(price, str):
        if not price.isdigit():
            return f"price {price!r} is not a number"
        rec["list_price_cents"] = int(price)
        fixed["price sent as text"] += 1
    if not isinstance(rec["list_price_cents"], int):
        return f"price {rec['list_price_cents']} is not a whole number of cents"
    if not 100 <= rec["list_price_cents"] <= 100_000:
        return f"price {rec['list_price_cents']} out of range"
    return None


def main(src, good_path, bad_path):
    fixed, rejected, good, bad = Counter(), Counter(), [], []
    for line in open(src, encoding="utf-8"):
        rec = json.loads(line)
        reason = check(rec, fixed)
        if reason:
            rejected[reason] += 1
            bad.append({"reason": reason, "record": json.loads(line)})
        else:
            good.append(rec)

    total = len(good) + len(bad)
    print(f"{total} records: {len(good)} accepted, {len(bad)} rejected")
    for what, n in sorted(fixed.items()):
        print(f"  fixed     {n:4}  {what}")
    for why, n in sorted(rejected.items()):
        print(f"  rejected  {n:4}  {why}")
    with open(bad_path, "w", encoding="utf-8") as out:
        out.writelines(json.dumps(b, ensure_ascii=False) + "\n" for b in bad)
    if len(bad) > MAX_REJECTED * total:
        print(f"STOP: {len(bad) / total:.0%} rejected is more than {MAX_REJECTED:.0%}; nothing loaded")
        return 1
    with open(good_path, "w", encoding="utf-8") as out:
        out.writelines(json.dumps(g, ensure_ascii=False) + "\n" for g in good)
    return 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:4]))
