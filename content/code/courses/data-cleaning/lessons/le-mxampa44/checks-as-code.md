---
title: Checks written as code
version: 1
---

Every lesson ended its cleaning with a check: a count before and after, a key that must be unique,
a sum that must not move. In a pipeline those checks are collected into one file and run after every
build, so they do not depend on anyone remembering them:

```schooling-example
{
  "language": "python",
  "file": "checks.py",
  "parts": [
    {
      "code": "\"\"\"Checks on the clean tables. Each one is a promise the pipeline makes.\"\"\"\nimport sys\n\nimport pandas as pd\n\n"
    },
    {
      "code": "customers = pd.read_csv(\"out/customers.csv\", dtype={\"customer_id\": str, \"birth_year\": \"Int64\"})\norders = pd.read_csv(\"out/orders.csv\", dtype={\"order_id\": str, \"customer_id\": str})\nchanges = pd.read_csv(\"out/changes.csv\", dtype=str)\n\n",
      "note": "**The clean tables, read back from disk** with their types, as anyone else would read them."
    },
    {
      "code": "checks = {\n    \"customer_id is unique\": customers[\"customer_id\"].is_unique,\n    \"birth years are blank or between 1920 and 2010\":\n        customers[\"birth_year\"].dropna().between(1920, 2010).all(),\n    \"order_id is unique\": orders[\"order_id\"].is_unique,\n    \"no total is negative\": (orders[\"total\"] >= 0).all(),\n    \"every order has at least one line\": (orders[\"items\"] >= 1).all(),\n    \"every change names its rule\": changes[\"rule\"].notna().all(),\n}\n",
      "note": "**Each check is a sentence and a test.** The sentence is what a failure prints."
    },
    {
      "code": "failed = [name for name, ok in checks.items() if not ok]\nfor name in failed:\n    print(f\"FAILED: {name}\")\nprint(f\"{len(checks) - len(failed)} of {len(checks)} checks passed\")\n",
      "note": "Name every check that failed, then count."
    },
    {
      "code": "sys.exit(1 if failed else 0)\n",
      "note": "**A failure ends with exit status 1**, so a scheduler or a person running it in a script sees it."
    }
  ]
}
```

```
ana@lab:~/clean$ python checks.py
6 of 6 checks passed
```

Each check is a promise the clean tables make to whoever uses them, written as a sentence and a
test. A check is only worth having if it fails when the promise is broken, so here is one broken on
purpose: the last line of the clean orders duplicated, as a careless append or a retried export
would do.

```
ana@lab:~/clean$ cp out/orders.csv /tmp/orders.csv && tail -1 /tmp/orders.csv >> out/orders.csv
ana@lab:~/clean$ python checks.py; echo exit status $?
FAILED: order_id is unique
5 of 6 checks passed
exit status 1
ana@lab:~/clean$ python run.py > /dev/null 2>&1; python checks.py
6 of 6 checks passed
```

The check names the broken promise, and the script ends with **exit status 1**. That number is what
makes the check usable by machines: a scheduled job, a `make` rule or a continuous-integration step
can stop on it, so a broken table is never published. The last command rebuilds `out/` from raw and
runs the checks again, and they pass, because the damage was to an output, which is disposable, and
not to an input, which is not.

Good checks have three things in common:

- **They test promises, not numbers.** "order_id is unique" survives next month's data; "there are
  28,526 orders" fails on the first new order. Counts belong in the log, where a person reads them.
- **They read the outputs as a stranger would**, from disk, with types declared, not from the
  objects the pipeline still holds in memory.
- **Each one is there because of a defect this course found.** A check for a problem nobody has met
  is cheap to write and easy to get wrong; a check for one that happened is evidence.
