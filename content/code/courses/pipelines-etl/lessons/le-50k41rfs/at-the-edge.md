---
title: Validating at the edge
version: 1
---

Lesson 6's `staging/prices.sql` already cleans the prices: it removes hyphens, trims names,
upper-cases the currency, casts text to numbers, and drops the missing. It does all of that
**silently**. Nobody learns how many prices were sent as text last night, or that a new publisher
has started sending them in reais with a comma, which `::integer` would turn into an error or into a
wrong number. Ana moves the decisions to where the records arrive, and makes each one say so:

```schooling-example
{
  "language": "python",
  "file": "validate_prices.py",
  "parts": [
    {
      "code": "\"\"\"Check every price the publishers sent before it is loaded.\n\nEach record is fixed where the fix is certain, rejected where it is not, and\ncounted either way. The good records go on to be loaded; the rejected ones go\nto quarantine with the reason; and if too many are rejected, nothing is loaded.\"\"\"\n",
      "note": "The policy, said once at the top: fix what is certain, reject what is not, count both, and stop the whole batch when too much is wrong."
    },
    {
      "code": "import json\nimport sys\nfrom collections import Counter\n\n",
      "note": "Only the standard library. `Counter` keeps a tally per reason."
    },
    {
      "code": "MAX_REJECTED = 0.05          # more than 5% rejected: the batch is wrong, not the records\n\n\n",
      "note": "**The threshold between a bad record and a bad batch.** Four missing prices in a thousand are the publishers being publishers; half the prices missing is a broken export, and loading the other half would be worse than loading none."
    },
    {
      "code": "def isbn13_ok(isbn):\n    \"\"\"The last digit of an ISBN-13 is a check digit over the other twelve.\"\"\"\n    if len(isbn) != 13 or not isbn.isdigit():\n        return False\n    total = sum(int(d) * (3 if i % 2 else 1) for i, d in enumerate(isbn[:12]))\n    return (10 - total % 10) % 10 == int(isbn[12])\n\n\n",
      "note": "**A rule a format check cannot make.** Thirteen digits is the shape of an ISBN; the last one being the right check digit is what makes it a real one. A typo in any digit fails it."
    },
    {
      "code": "def check(rec, fixed):\n    \"\"\"Return the reason to reject rec, or None; fix what can be fixed, in place.\"\"\"\n",
      "note": "One function per record. It returns the reason to reject, or `None`, and it fixes in place what can be fixed, counting each fix."
    },
    {
      "code": "    if \"-\" in rec[\"isbn\"]:\n        rec[\"isbn\"] = rec[\"isbn\"].replace(\"-\", \"\")\n        fixed[\"isbn written with hyphens\"] += 1\n",
      "note": "**A certain fix**: the hyphens in Maré's ISBNs carry no information, so removing them loses nothing."
    },
    {
      "code": "    if not isbn13_ok(rec[\"isbn\"]):\n        return \"isbn fails its check digit\"\n",
      "note": "And then the real check, on the fixed value."
    },
    {
      "code": "    if rec[\"publisher\"] != rec[\"publisher\"].strip():\n        rec[\"publisher\"] = rec[\"publisher\"].strip()\n        fixed[\"publisher with stray spaces\"] += 1\n",
      "note": "Granito's trailing space, the same kind of certain fix."
    },
    {
      "code": "    if rec[\"currency\"] != \"BRL\":\n        if rec[\"currency\"].upper() != \"BRL\":\n            return f\"currency {rec['currency']!r}\"\n        rec[\"currency\"] = \"BRL\"\n        fixed[\"currency in lower case\"] += 1\n",
      "note": "`brl` is fixed; any other currency is rejected rather than converted. Converting would mean choosing a rate, and that is not a decision a validator should take on its own."
    },
    {
      "code": "    price = rec[\"list_price_cents\"]\n    if price is None:\n        return \"price missing\"\n    if isinstance(price, str):\n        if not price.isdigit():\n            return f\"price {price!r} is not a number\"\n        rec[\"list_price_cents\"] = int(price)\n        fixed[\"price sent as text\"] += 1\n",
      "note": "**A missing price is rejected, never filled in.** Nothing in the record says what the price should be, and a guess would be loaded as a fact. A price sent as digits in a string is certain and is fixed; anything else in a string is rejected."
    },
    {
      "code": "    if not 100 <= rec[\"list_price_cents\"] <= 100_000:\n        return f\"price {rec['list_price_cents']} out of range\"\n    return None\n\n\n",
      "note": "A plausible range for a book's list price, in cents: one real to a thousand. A price outside it is far more likely a mistake than a book."
    },
    {
      "code": "src, good_path, bad_path = sys.argv[1:4]\nfixed, rejected, good, bad = Counter(), Counter(), [], []\nfor line in open(src, encoding=\"utf-8\"):\n    rec = json.loads(line)\n    reason = check(rec, fixed)\n    if reason:\n        rejected[reason] += 1\n        bad.append({\"reason\": reason, \"record\": json.loads(line)})\n    else:\n        good.append(rec)\n\n",
      "note": "Each record goes one way or the other. The rejected one is kept **as it arrived**, not as half-fixed, beside its reason."
    },
    {
      "code": "total = len(good) + len(bad)\nprint(f\"{total} records: {len(good)} accepted, {len(bad)} rejected\")\nfor what, n in sorted(fixed.items()):\n    print(f\"  fixed     {n:4}  {what}\")\nfor why, n in sorted(rejected.items()):\n    print(f\"  rejected  {n:4}  {why}\")\n",
      "note": "**The tally is the report.** Every fix and every rejection is counted, so a fix that used to happen eighty times and now happens eight hundred is visible on the first night it does."
    },
    {
      "code": "with open(bad_path, \"w\", encoding=\"utf-8\") as out:\n    out.writelines(json.dumps(b, ensure_ascii=False) + \"\\n\" for b in bad)\n",
      "note": "The quarantine file is written whatever happens next, so the rejected records can always be read."
    },
    {
      "code": "if len(bad) > MAX_REJECTED * total:\n    print(f\"STOP: {len(bad) / total:.0%} rejected is more than {MAX_REJECTED:.0%}; nothing loaded\")\n    sys.exit(1)\n",
      "note": "**Stop, with a non-zero exit**, so that whatever runs this — Airflow, `make`, a shell script with `set -e` — stops too."
    },
    {
      "code": "with open(good_path, \"w\", encoding=\"utf-8\") as out:\n    out.writelines(json.dumps(g, ensure_ascii=False) + \"\\n\" for g in good)",
      "note": "Only now are the good records written for the loader."
    }
  ]
}
```

```
ana@vm:~/etl$ mkdir -p quarantine; python validate_prices.py landing/prices.jsonl landing/prices.valid.jsonl quarantine/prices.jsonl
1071 records: 1067 accepted, 4 rejected
  fixed       81  currency in lower case
  fixed       84  isbn written with hyphens
  fixed       81  price sent as text
  fixed       85  publisher with stray spaces
  rejected     4  price missing
ana@vm:~/etl$ cat quarantine/prices.jsonl
{"reason": "price missing", "record": {"isbn": "9786542137312", "publisher": "Litoral", "list_price_cents": null, "currency": "BRL", "updated_at": "2026-01-07T18:51:00-03:00"}}
{"reason": "price missing", "record": {"isbn": "9786528944132", "publisher": "Oásis", "list_price_cents": null, "currency": "BRL", "updated_at": "2026-02-11T04:18:00-03:00"}}
{"reason": "price missing", "record": {"isbn": "978-65-64226-84-1", "publisher": "Maré", "list_price_cents": null, "currency": "BRL", "updated_at": "2026-02-25T03:14:00-03:00"}}
{"reason": "price missing", "record": {"isbn": "978-65-67767-15-0", "publisher": "Maré", "list_price_cents": null, "currency": "BRL", "updated_at": "2026-03-16T10:45:00-03:00"}}
```

Every record accounted for: 1,067 accepted, four rejected, and a line for each kind of fix with how
often it was needed. The counts are the publishers' habits, measured: Maré hyphenates its ISBNs,
Granito's name has a trailing space, Farol sends prices as text in lower-case reais. If one of those
numbers jumps tomorrow, something changed at a publisher, and Ana will know which.

The four rejected records are in quarantine, **as they arrived**, each with the reason. Nobody has to
reconstruct what was wrong with them from a log line. They are prices the shop will not have until a
publisher sends them again, and the quarantine file is what Ana sends the publisher to ask.

The validator writes `landing/prices.valid.jsonl` for the loader. Pointing `load_raw.py` at it
instead of the raw file is a one-line change that this lesson leaves to the drill; the point here is
that from now on, staging can trust that every price it reads was checked, and that every price that
was not loaded is written down somewhere with a reason.
