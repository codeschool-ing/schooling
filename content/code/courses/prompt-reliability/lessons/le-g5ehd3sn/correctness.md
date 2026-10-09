---
title: Correctness, one mistake at a time
version: 2
---

Accuracy is the first number anybody reports and the one that says least. It counts the right
answers and treats every wrong one as the same wrong. **A confusion matrix keeps every mistake
apart**: one row for each label a person gave, one column for each label the reply gave. This
program draws one from a run file, reading the replies the way `pl check --lenient` does not: a
reply that does not parse, or names a label not on the list, goes in a column of its own. Save it as
`confusion.py`:

```python
"""confusion: every mistake in a run, one cell each, with recall and precision."""
import argparse

from pl import LABELS, parse, read_jsonl

p = argparse.ArgumentParser(prog="confusion")
p.add_argument("run")
p.add_argument("--field", default="category", choices=sorted(LABELS))
a = p.parse_args()

rows = read_jsonl(a.run)
expect = {c["id"]: c["expect"] for c in read_jsonl(rows[0]["cases"])}
labels = LABELS[a.field]
cols = labels + ["(bad)"]
cells = {(e, g): 0 for e in labels for g in cols}
for r in rows:
    got = (parse(r["text"]) or {}).get(a.field)
    cells[expect[r["case"]][a.field], got if got in labels else "(bad)"] += 1

print("%-10s" % "expected" + "".join("%9s" % c for c in cols) + "   recall")
for e in labels:
    total = sum(cells[e, g] for g in cols)
    recall = "%.2f" % (cells[e, e] / total) if total else "-"
    print("%-10s" % e + "".join("%9d" % cells[e, g] for g in cols) + "%9s" % recall)
precision = []
for g in labels:
    total = sum(cells[e, g] for e in labels)
    precision.append("%.2f" % (cells[g, g] / total) if total else "-")
print("%-10s" % "precision" + "".join("%9s" % x for x in precision))
right = sum(cells[e, e] for e in labels)
print("\naccuracy %d/%d = %.2f" % (right, len(rows), right / len(rows)))
```

It imports `LABELS` and `parse()` from `pl.py`, so the labels and the parsing are the harness's own.
Here is `v6-escaped.txt` over all seventy messages, the forty dev cases and the thirty holdout ones
that lesson 5 joined into `cases/all.jsonl`:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6-all.jsonl
70 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/v6-all.jsonl
ana@lab:~/triage$ python3 confusion.py runs/v6-all.jsonl
expected    billing delivery  returns  account    other    (bad)   recall
billing           4        0        6        5        1        0     0.25
delivery          0        9        5        0        0        0     0.64
returns           0        1       14        0        0        1     0.88
account           0        1        3        9        1        0     0.64
other             0        0        1        0        9        0     0.90
precision      1.00     0.82     0.48     0.64     0.82

accuracy 45/70 = 0.64
```

The diagonal is the replies that were right, 45 of 70. Every other cell is one particular mistake:
row `billing`, column `returns`, 6, means six billing messages were sorted as returns. `(bad)` holds
replies with no usable label at all, which the next section counts as format.

## Recall and precision

The two numbers at the edges answer different questions.

**Recall reads along a row**: of the messages that really were billing, what share did the prompt
call billing? Four of sixteen, 0.25. Twelve billing messages went somewhere else, six of them to
returns and five to account, and the billing team will never see them unless somebody forwards them.

**Precision reads down a column**: of the messages the prompt called returns, what share were
returns? Fourteen of twenty-nine, 0.48. More than half of the returns team's tickets belong to
someone else. Billing has the opposite shape, precision 1.00: when this prompt says billing it is
right, and it says billing four times in seventy. **Under this prompt `returns` is
`llama3.2:3b`'s catch-all**: six billing messages went there, five delivery and three account, and
the matrix says so in one column where the accuracy says only 0.64.

A prompt can raise one by lowering the other. Calling everything billing would take billing recall
to 1.00 and its precision to the floor. That is why the two are reported together, per label.

## Which mistakes cost more

The cells do not cost the same. Urgency shows it best:

```
ana@lab:~/triage$ python3 confusion.py runs/v6-all.jsonl --field urgency
expected        low   normal     high    (bad)   recall
low              22        2        0        0     0.92
normal            3        4       22        1     0.13
high              1        0       15        0     0.94
precision      0.85     0.67     0.41

accuracy 41/70 = 0.59
```

Read the `normal` row: of thirty messages a person called normal, the prompt called twenty-two high.
Recall for normal is 0.13. Read the `high` column: forty-one per cent of what it calls high is high.
And the cell that would cost most, a high message sorted as normal, holds zero: high recall is 0.94,
and the one high message it missed it called low.

So this prompt fails in the cheap direction. A support team behind it would find most of its queue
marked urgent, and would learn within a week to ignore the label, which is its own cost: **a label
everybody ignores protects nobody**. Urgency accuracy is 41 of 70, and that number counts an urgent
message missed exactly like a routine one escalated. They do not cost the same. Decide what each
kind of mistake costs before you read the matrix, and report the expensive cells by name.
*Twenty-two normal sorted high, no high sorted normal* is a sentence somebody acts on; *0.59* is
not.
